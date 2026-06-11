#!/usr/bin/env python3
"""Live sudoku-recognition viewer: point a webcam at a puzzle page and
verify what the pipeline sees.

  python3 tools/live-viewer.py                 # webcam
  python3 tools/live-viewer.py --camera 1      # another camera
  python3 tools/live-viewer.py --image x.heic [--rotate 270]   # still photo

Overlay, every frame (fast, pure OpenCV):
  - green outline around every detected grid, with its index
  - a small dot on every cell classified as containing a digit

On demand (tesseract, ~10s/grid, runs in a background thread):
  SPACE  OCR the grid nearest the frame center; digits are projected
         back onto the page - compare them with the print
  a      OCR all detected grids
  p      print the recognized 81-char strings to the terminal
  s      save an annotated snapshot to /tmp
  q      quit
"""

import argparse
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
        try:
            for i in indexes:
                line = so.read_grid(gray, quads[i])
                with self.lock:
                    self.results[i] = line
        finally:
            with self.lock:
                self.busy = False


def overlay(frame, gray, quads, worker):
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
            for k, f in enumerate(filled):
                if f:
                    x, y = centers[k].astype(int)
                    cv2.circle(frame, (x, y), 4, YELLOW, -1)
            label += f"  {sum(filled)} filled"
        cv2.putText(frame, label, (cx - 40, cy),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, GREEN, 2)
    if worker.busy:
        cv2.putText(frame, "OCR running...", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, YELLOW, 2)
    return frame


def nearest_grid(quads, shape):
    if not quads:
        return None
    h, w = shape[:2]
    center = np.array([w / 2, h / 2])
    return int(np.argmin([np.linalg.norm(q.mean(axis=0) - center)
                          for q in quads]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--camera", type=int, default=0)
    ap.add_argument("--image", help="run on a still photo instead of webcam")
    ap.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270])
    args = ap.parse_args()

    worker = OcrWorker()
    still = so.load(args.image, args.rotate) if args.image else None
    cap = None
    if still is None:
        cap = cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            sys.exit("cannot open camera (grant Terminal camera access in "
                     "System Settings > Privacy & Security > Camera)")

    last_quads = []
    while True:
        if still is not None:
            frame = still.copy()
        else:
            ok, frame = cap.read()
            if not ok:
                time.sleep(0.05)
                continue
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        quads = so.find_grids(gray)
        if len(quads) != len(last_quads):
            worker.results.clear()      # layout changed, old digits are stale
        last_quads = quads

        view = overlay(frame, gray, quads, worker)
        cv2.imshow("hudoku live", view)

        key = cv2.waitKey(30 if still is None else 200) & 0xFF
        if key == ord("q"):
            break
        elif key == ord(" ") and quads:
            target = nearest_grid(quads, frame.shape)
            worker.submit(gray, quads, [target])
        elif key == ord("a") and quads:
            worker.submit(gray, quads, range(len(quads)))
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


if __name__ == "__main__":
    main()
