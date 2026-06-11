#!/usr/bin/env python3
"""Extract sudoku grids from a photographed puzzle page.

Usage: python3 tools/grid-ocr.py IMAGE [--rotate 90]

Finds every grid-sized quadrilateral on the page, flattens it with a
perspective transform, splits it into 9x9 cells and OCRs each cell with
Tesseract. Prints one 81-character line per grid ('.' = empty, '?' =
unreadable - fix by hand), in reading order (left-to-right, top-to-bottom),
plus an ASCII rendering on stderr for eyeballing.

HEIC input is converted via macOS `sips`.
"""

import argparse
import subprocess
import sys
import tempfile

import cv2
import numpy as np
import pytesseract


def load(path, rotate):
    if path.lower().endswith(".heic"):
        tmp = tempfile.mktemp(suffix=".png")
        subprocess.run(["sips", "-s", "format", "png", path, "--out", tmp],
                       capture_output=True, check=True)
        path = tmp
    img = cv2.imread(path)
    if img is None:
        sys.exit(f"cannot read {path}")
    rotations = {90: cv2.ROTATE_90_CLOCKWISE, 180: cv2.ROTATE_180,
                 270: cv2.ROTATE_90_COUNTERCLOCKWISE}
    if rotate in rotations:
        img = cv2.rotate(img, rotations[rotate])
    return img


def find_grids(gray):
    """Quadrilaterals big enough and square enough to be a sudoku grid."""
    thr = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                cv2.THRESH_BINARY_INV, 31, 10)
    thr = cv2.dilate(thr, np.ones((3, 3), np.uint8))
    contours, _ = cv2.findContours(thr, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    page_area = gray.shape[0] * gray.shape[1]
    quads = []
    for c in contours:
        area = cv2.contourArea(c)
        if area < 0.015 * page_area:
            continue
        approx = cv2.approxPolyDP(c, 0.02 * cv2.arcLength(c, True), True)
        if len(approx) != 4:
            continue
        q = order_points(approx.reshape(4, 2).astype(np.float32))
        w = np.linalg.norm(q[1] - q[0])
        h = np.linalg.norm(q[3] - q[0])
        if 0.75 < w / h < 1.33:
            quads.append(q)
    # reading order by grid centers
    quads.sort(key=lambda q: (round(q.mean(axis=0)[1] / 300), q.mean(axis=0)[0]))
    return quads


def order_points(pts):
    s = pts.sum(axis=1)
    d = np.diff(pts, axis=1).ravel()
    return np.array([pts[s.argmin()], pts[d.argmin()],
                     pts[s.argmax()], pts[d.argmax()]], dtype=np.float32)


def warp(gray, quad, size=900):
    dst = np.array([[0, 0], [size, 0], [size, size], [0, size]], dtype=np.float32)
    m = cv2.getPerspectiveTransform(quad, dst)
    return cv2.warpPerspective(gray, m, (size, size))


def ocr_cell(cell):
    """cell: 100x100 grayscale. '.' if blank, digit, or '?' if unsure."""
    inner = cell[18:82, 18:82]
    _, binary = cv2.threshold(inner, 0, 255,
                              cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    # ignore specks touching the border (grid line bleed)
    n, labels, stats, _ = cv2.connectedComponentsWithStats(binary)
    mask = np.zeros_like(binary)
    for i in range(1, n):
        x, y, w, h, area = stats[i]
        if area > 40 and x > 0 and y > 0 and x + w < 64 and y + h < 64:
            mask[labels == i] = 255
    if (mask > 0).mean() < 0.02:
        return "."
    padded = cv2.copyMakeBorder(255 - mask, 20, 20, 20, 20,
                                cv2.BORDER_CONSTANT, value=255)
    txt = pytesseract.image_to_string(
        padded, config="--psm 10 -c tessedit_char_whitelist=123456789").strip()
    return txt[0] if txt and txt[0] in "123456789" else "?"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270])
    ap.add_argument("--strips", metavar="DIR",
                    help="also write annotated 3-row strip PNGs (for manual reading)")
    args = ap.parse_args()

    img = load(args.image, args.rotate)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    grids = find_grids(gray)
    print(f"{len(grids)} grid(s) found", file=sys.stderr)

    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    for gi, quad in enumerate(grids):
        flat = warp(gray, quad)
        if args.strips:
            vis = clahe.apply(flat)
            for k in range(0, 10, 3):
                cv2.line(vis, (k * 100, 0), (k * 100, 900), 0, 7)
            for s in range(3):
                cv2.imwrite(f"{args.strips}/grid{gi + 1}-rows{s * 3 + 1}-{s * 3 + 3}.png",
                            vis[s * 300:(s + 1) * 300, :])
        cells = [ocr_cell(flat[r * 100:(r + 1) * 100, c * 100:(c + 1) * 100])
                 for r in range(9) for c in range(9)]
        line = "".join(cells)
        print(f"--- grid {gi + 1} (givens: {sum(ch != '.' for ch in line)})",
              file=sys.stderr)
        for r in range(9):
            print("   " + " ".join(line[r * 9:(r + 1) * 9]), file=sys.stderr)
        print(line)


if __name__ == "__main__":
    main()
