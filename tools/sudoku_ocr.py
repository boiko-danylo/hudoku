"""Shared sudoku-page recognition pieces: grid detection, perspective
flattening, cell segmentation and per-cell OCR. Used by grid-ocr.py
(batch CLI) and live-viewer.py (webcam overlay)."""

import subprocess
import sys
import tempfile

import cv2
import numpy as np
import pytesseract


def load(path, rotate=0):
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


def order_points(pts):
    s = pts.sum(axis=1)
    d = np.diff(pts, axis=1).ravel()
    return np.array([pts[s.argmin()], pts[d.argmin()],
                     pts[s.argmax()], pts[d.argmax()]], dtype=np.float32)


def find_grids(gray, min_area_frac=0.015):
    """Quadrilaterals big enough and square enough to be a sudoku grid."""
    thr = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                cv2.THRESH_BINARY_INV, 31, 10)
    thr = cv2.dilate(thr, np.ones((3, 3), np.uint8))
    contours, _ = cv2.findContours(thr, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    page_area = gray.shape[0] * gray.shape[1]
    quads = []
    for c in contours:
        if cv2.contourArea(c) < min_area_frac * page_area:
            continue
        approx = cv2.approxPolyDP(c, 0.02 * cv2.arcLength(c, True), True)
        if len(approx) != 4:
            continue
        q = order_points(approx.reshape(4, 2).astype(np.float32))
        w = np.linalg.norm(q[1] - q[0])
        h = np.linalg.norm(q[3] - q[0])
        if h > 0 and 0.75 < w / h < 1.33:
            quads.append(q)
    quads.sort(key=lambda q: (round(q.mean(axis=0)[1] / 300), q.mean(axis=0)[0]))
    return quads


def homography(quad, size=900):
    dst = np.array([[0, 0], [size, 0], [size, size], [0, size]], dtype=np.float32)
    return cv2.getPerspectiveTransform(quad, dst)


def warp(gray, quad, size=900):
    return cv2.warpPerspective(gray, homography(quad, size), (size, size))


# Segmentation parameters, tuned against corpus ground truth on the
# magazine pages at several resolutions (99.6% cell accuracy; see git log).
THRESH_BLOCK = 51
THRESH_C = 12
MIN_AREA = 0.03   # of the 70x70 cell interior
MIN_H, MAX_H = 0.25, 0.95
MAX_W = 0.85
CENTROID_MARGIN = 10


def grid_threshold(flat):
    """Ink mask of a whole warped grid; robust to uneven lighting."""
    return cv2.adaptiveThreshold(flat, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                 cv2.THRESH_BINARY_INV, THRESH_BLOCK, THRESH_C)


def cell_mask(thr, r, c):
    """Digit mask of cell (r, c) from a grid ink mask, or None if empty.
    Keeps only digit-shaped components: big enough, tall enough, not a
    grid-line sliver, centroid away from the borders."""
    inner = thr[r * 100 + 15:r * 100 + 85, c * 100 + 15:c * 100 + 85]
    n, labels, stats, centroids = cv2.connectedComponentsWithStats(inner)
    mask = None
    for i in range(1, n):
        _, _, w, h, area = stats[i]
        if area < MIN_AREA * 4900 or area > 0.5 * 4900:
            continue
        if h < MIN_H * 70 or h > MAX_H * 70 or w > MAX_W * 70:
            continue
        cx, cy = centroids[i]
        if not (CENTROID_MARGIN < cx < 70 - CENTROID_MARGIN
                and CENTROID_MARGIN < cy < 70 - CENTROID_MARGIN):
            continue
        if mask is None:
            mask = np.zeros_like(inner)
        mask[labels == i] = 255
    return mask


def ocr_mask(mask):
    padded = cv2.copyMakeBorder(255 - mask, 20, 20, 20, 20,
                                cv2.BORDER_CONSTANT, value=255)
    txt = pytesseract.image_to_string(
        padded, config="--psm 10 -c tessedit_char_whitelist=123456789").strip()
    return txt[0] if txt and txt[0] in "123456789" else "?"


def read_grid(gray, quad):
    """OCR a full grid -> 81-char string."""
    thr = grid_threshold(warp(gray, quad))
    out = []
    for r in range(9):
        for c in range(9):
            mask = cell_mask(thr, r, c)
            out.append("." if mask is None else ocr_mask(mask))
    return "".join(out)


def filled_map(gray, quad):
    """Fast 81-bool list: which cells contain a digit."""
    thr = grid_threshold(warp(gray, quad))
    return [cell_mask(thr, r, c) is not None
            for r in range(9) for c in range(9)]


def cell_centers_on_image(quad, size=900):
    """Image coordinates of the 81 cell centers, via inverse homography."""
    inv = np.linalg.inv(homography(quad, size))
    # row-major: index r*9+c matches puzzle-string order
    pts = np.array([[[c * 100 + 50, r * 100 + 50]]
                    for r in range(9) for c in range(9)], dtype=np.float32)
    return cv2.perspectiveTransform(pts, inv).reshape(81, 2)
