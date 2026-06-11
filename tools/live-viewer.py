#!/usr/bin/env python3
"""Live sudoku-recognition viewer: point a webcam at a puzzle page and
verify what the pipeline sees.

  python3 tools/live-viewer.py                 # webcam
  python3 tools/live-viewer.py --camera 1      # another camera
  python3 tools/live-viewer.py --image x.heic [--rotate 270]   # still photo

Overlay, every frame (fast, pure OpenCV):
  - green outline around every detected grid, with its index
  - a small dot on every cell classified as containing a digit

Keys:
  SPACE  pause / resume the feed (freeze a sharp frame, then OCR it)
  o      OCR the grid nearest the frame center (background thread);
         digits are projected back onto the page - compare with print
  a      OCR all detected grids
  v      cycle view: normal -> detect (page ink mask) -> cells (warped
         center grid + the exact mask the cell classifier sees)
  c      cycle to the next camera (e.g. switch to iPhone Continuity Camera)
  p      print the recognized 81-char strings to the terminal
  s      save an annotated snapshot to /tmp
  q/ESC  quit (closing the window or Ctrl-C also works)
"""

import argparse
import collections
import os
import subprocess
import sys
import threading
import time

import cv2
import numpy as np

import sudoku_ocr as so

GREEN = (0, 230, 0)
YELLOW = (0, 220, 220)
RED = (0, 0, 230)


class OcrWorker:
    """One background OCR pass at a time; results keyed by grid index."""

    def __init__(self):
        self.results = {}      # grid index -> 81-char string
        self.busy = False
        self.last_secs = None
        self.error = None
        self.lock = threading.Lock()

    def submit(self, gray, quads, indexes):
        with self.lock:
            if self.busy:
                return
            self.busy = True
        threading.Thread(target=self._run,
                         args=(gray.copy(), list(quads), list(indexes)),
                         daemon=True).start()

    def _run(self, gray, quads, indexes):
        t0 = time.time()
        try:
            for i in indexes:
                line = so.read_grid(gray, quads[i])
                with self.lock:
                    self.results[i] = line
        except Exception as e:           # surface, don't swallow
            with self.lock:
                self.error = f"OCR failed: {e}"
        finally:
            with self.lock:
                self.busy = False
                self.last_secs = time.time() - t0


def focus_window():
    """macOS: a HighGUI window opened from a terminal script doesn't get
    keyboard focus, so waitKey never sees q/SPACE. Activate ourselves."""
    if sys.platform == "darwin":
        subprocess.run(
            ["osascript", "-e",
             'tell application "System Events" to set frontmost of '
             f'(every process whose unix id is {os.getpid()}) to true'],
            capture_output=True)


def hud(view, lines):
    pad, lh = 8, 22
    w = max(cv2.getTextSize(t, cv2.FONT_HERSHEY_SIMPLEX, 0.55, 1)[0][0] for t in lines)
    cv2.rectangle(view, (6, 6), (6 + w + 2 * pad, 6 + lh * len(lines) + pad), (0, 0, 0), -1)
    for i, t in enumerate(lines):
        cv2.putText(view, t, (6 + pad, 6 + lh * (i + 1)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, GREEN, 1)


def metrics_lines(frame, gray, quads, fps, worker, cam_idx, mode, status=""):
    lines = [f"{frame.shape[1]}x{frame.shape[0]}  fps {fps:.1f}  view:{mode}"
             + (f"  cam {cam_idx}" if cam_idx is not None else "")]
    lines.append(f"grids: {len(quads)}  bright {gray.mean():.0f}  contrast {gray.std():.0f}")
    target = nearest_grid(quads, frame.shape)
    if target is not None:
        q = quads[target]
        edge = (np.linalg.norm(q[1] - q[0]) + np.linalg.norm(q[2] - q[3])) / 2
        x0, y0 = q.min(axis=0).astype(int).clip(0)
        x1, y1 = q.max(axis=0).astype(int)
        roi = gray[y0:y1, x0:x1]
        focus = cv2.Laplacian(roi, cv2.CV_64F).var() if roi.size else 0
        quality = "ok" if edge / 9 >= 22 else "MOVE CLOSER"
        lines.append(f"grid #{target + 1}: {edge / 9:.0f} px/cell ({quality})  focus {focus:.0f}")
    with worker.lock:
        if worker.busy:
            lines.append("OCR running...")
        elif worker.error:
            lines.append(worker.error)
        elif worker.last_secs is not None:
            lines.append(f"last OCR {worker.last_secs:.1f}s")
    if status:
        lines.append(status)
    return lines


def debug_view(frame, gray, quads, mode):
    """What the algorithms actually see."""
    if mode == "detect":
        thr = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                    cv2.THRESH_BINARY_INV, 31, 10)
        view = cv2.cvtColor(thr, cv2.COLOR_GRAY2BGR)
        for q in quads:
            cv2.polylines(view, [q.astype(int)], True, GREEN, 2)
        return view
    if mode == "cells":
        target = nearest_grid(quads, frame.shape)
        if target is None:
            return frame
        flat = so.warp(gray, quads[target])
        thr = so.grid_threshold(flat)
        marked = cv2.cvtColor(thr, cv2.COLOR_GRAY2BGR)
        for r in range(9):
            for c in range(9):
                if so.cell_mask(thr, r, c) is not None:
                    cv2.rectangle(marked, (c * 100 + 4, r * 100 + 4),
                                  (c * 100 + 96, r * 100 + 96), GREEN, 3)
        side = np.hstack([cv2.cvtColor(flat, cv2.COLOR_GRAY2BGR), marked])
        scale = frame.shape[1] / side.shape[1]
        return cv2.resize(side, None, fx=scale, fy=scale)
    return None


def overlay(frame, gray, quads, worker, history=None):
    for gi, quad in enumerate(quads):
        cv2.polylines(frame, [quad.astype(int)], True, GREEN, 2)
        cx, cy = quad.mean(axis=0).astype(int)
        label = f"#{gi + 1}"
        with worker.lock:
            line = worker.results.get(gi)
        centers = so.cell_centers_on_image(quad)
        if line:
            for k, ch in enumerate(line):
                if ch == ".":
                    continue
                x, y = centers[k].astype(int)
                color, glyph = (RED, "?") if ch == "?" else (GREEN, ch)
                cv2.putText(frame, glyph, (x - 8, y + 8),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
            label += f"  {sum(c not in '.?' for c in line)} digits"
        else:
            filled = so.filled_map(gray, quad)
            if history is not None:
                history[gi].append(filled)
                votes = history[gi]
                filled = [sum(v[k] for v in votes) * 2 > len(votes)
                          for k in range(81)]
            for k, f in enumerate(filled):
                if f:
                    x, y = centers[k].astype(int)
                    cv2.circle(frame, (x, y), 4, YELLOW, -1)
            label += f"  {sum(filled)} filled"
        cv2.putText(frame, label, (cx - 40, cy),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, GREEN, 2)
    return frame


def open_camera(start, tried_from=None):
    """Open camera index `start`, or scan forward for the next one that works."""
    for offset in range(8):
        idx = (start + offset) % 8
        if idx == tried_from:
            continue
        cap = cv2.VideoCapture(idx)
        if cap.isOpened():
            ok, _ = cap.read()
            if ok:
                return idx, cap
            cap.release()
    return None, None


def nearest_grid(quads, shape):
    if not quads:
        return None
    h, w = shape[:2]
    center = np.array([w / 2, h / 2])
    return int(np.argmin([np.linalg.norm(q.mean(axis=0) - center)
                          for q in quads]))


def run():
    ap = argparse.ArgumentParser()
    ap.add_argument("--camera", type=int, default=0)
    ap.add_argument("--image", help="run on a still photo instead of webcam")
    ap.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270])
    args = ap.parse_args()

    worker = OcrWorker()
    still = so.load(args.image, args.rotate) if args.image else None
    cap = None
    cam_idx = args.camera
    if still is None:
        cam_idx, cap = open_camera(args.camera)
        if cap is None:
            sys.exit("cannot open any camera (grant Terminal camera access in "
                     "System Settings > Privacy & Security > Camera)")
        print(f"camera {cam_idx} (press c to cycle)")

    cv2.namedWindow("hudoku live", cv2.WINDOW_AUTOSIZE)
    focus_window()
    paused, frozen = False, None
    status, status_until = "", 0.0
    history = collections.defaultdict(lambda: collections.deque(maxlen=5))
    last_quads = []
    modes = ["normal", "detect", "cells"]
    mode_i = 0
    fps, t_prev = 0.0, time.time()
    while True:
        if still is not None:
            frame = still.copy()
        elif paused and frozen is not None:
            frame = frozen.copy()
        else:
            ok, frame = cap.read()
            if not ok:
                time.sleep(0.05)
                continue
            frozen = frame
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        quads = so.find_grids(gray)
        if len(quads) != len(last_quads):
            worker.results.clear()      # layout changed, old digits are stale
            history.clear()
        last_quads = quads

        now = time.time()
        fps = 0.9 * fps + 0.1 / max(now - t_prev, 1e-6)
        t_prev = now

        mode = modes[mode_i]
        view = debug_view(frame, gray, quads, mode)
        if view is None:
            view = overlay(frame, gray, quads, worker, history)
        hud(view, metrics_lines(frame, gray, quads, fps, worker,
                                cam_idx if cap is not None else None, mode,
                                ("PAUSED  " if paused else "")
                                + (status if time.time() < status_until else "")))
        cv2.imshow("hudoku live", view)

        key = cv2.waitKey(30 if still is None else 200) & 0xFF
        if key in (ord("q"), 27):  # q or ESC
            break
        if cv2.getWindowProperty("hudoku live", cv2.WND_PROP_VISIBLE) < 1:
            break               # window closed with the mouse
        elif key == ord(" ") and still is None:
            paused = not paused
            status, status_until = ("PAUSED" if paused else "live"), time.time() + 2
        elif key == ord("o"):
            if quads:
                target = nearest_grid(quads, frame.shape)
                worker.submit(gray, quads, [target])
                status, status_until = f"OCR queued for grid #{target + 1}", time.time() + 2
            else:
                status, status_until = "no grid detected to OCR", time.time() + 2
        elif key == ord("a"):
            if quads:
                worker.submit(gray, quads, range(len(quads)))
                status, status_until = f"OCR queued for {len(quads)} grids", time.time() + 2
            else:
                status, status_until = "no grid detected to OCR", time.time() + 2
        elif key != 255:
            status, status_until = f"key {chr(key) if 32 <= key < 127 else key}", time.time() + 1
        elif key == ord("v"):
            mode_i = (mode_i + 1) % len(modes)
        elif key == ord("c") and cap is not None:
            cap.release()
            new_idx, new_cap = open_camera(cam_idx + 1, tried_from=None)
            if new_cap is not None:
                cam_idx, cap = new_idx, new_cap
                worker.results.clear()
                history.clear()
                print(f"camera {cam_idx}")
            else:
                cam_idx, cap = open_camera(cam_idx)
        elif key == ord("p"):
            with worker.lock:
                for gi in sorted(worker.results):
                    print(f"grid {gi + 1}: {worker.results[gi]}")
        elif key == ord("s"):
            out = f"/tmp/hudoku-live-{int(time.time())}.png"
            cv2.imwrite(out, view)
            print("saved", out)

    if cap:
        cap.release()
    cv2.destroyAllWindows()


def main():
    try:
        run()
    except KeyboardInterrupt:
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
