#!/usr/bin/env python3
"""Extract sudoku grids from a photographed puzzle page.

Usage: python3 ocr/grid-ocr.py IMAGE [--rotate 270] [--strips DIR]

Finds every grid-sized quadrilateral on the page, flattens it, splits it
into 9x9 cells and OCRs each cell with Tesseract. Prints one 81-character
line per grid ('.' = empty, '?' = unreadable - fix by hand), in reading
order, plus an ASCII rendering on stderr for eyeballing.

Tesseract is unreliable on newsprint; --strips writes annotated 3-row
band PNGs per grid, which are the ground truth for manual reading.
Verify transcriptions with: stack runghc corpus/verify.hs
"""

import argparse
import sys

import cv2

import sudoku_ocr as so


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270])
    ap.add_argument("--strips", metavar="DIR",
                    help="also write annotated 3-row strip PNGs (for manual reading)")
    args = ap.parse_args()

    img = so.load(args.image, args.rotate)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    grids = so.find_grids(gray)
    print(f"{len(grids)} grid(s) found", file=sys.stderr)

    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    for gi, quad in enumerate(grids):
        if args.strips:
            vis = clahe.apply(so.warp(gray, quad))
            for k in range(0, 10, 3):
                cv2.line(vis, (k * 100, 0), (k * 100, 900), 0, 7)
            for s in range(3):
                cv2.imwrite(f"{args.strips}/grid{gi + 1}-rows{s * 3 + 1}-{s * 3 + 3}.png",
                            vis[s * 300:(s + 1) * 300, :])
        line = so.read_grid(gray, quad)
        print(f"--- grid {gi + 1} (givens: {sum(ch != '.' for ch in line)})",
              file=sys.stderr)
        for r in range(9):
            print("   " + " ".join(line[r * 9:(r + 1) * 9]), file=sys.stderr)
        print(line)


if __name__ == "__main__":
    main()
