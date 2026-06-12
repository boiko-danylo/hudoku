#!/usr/bin/env python3
"""Harvest digit templates from corpus-verified puzzle photos.

  python3 ocr/harvest-templates.py --tag mag1 --rotate 270 \
      /path/page1.heic:197-202 /path/page2.heic:203-208

Each argument is PHOTO:IDS where IDS select corpus entries (a-b range or
comma list). Detected grids are matched to corpus puzzles by their
filled-cell pattern; every given digit becomes a labeled sample. Mean
templates per digit are stored in ocr/digit-templates.npz under keys
'digit:tag' - existing tags other than --tag are preserved, so each
publication's font is one harvest run.
"""

import argparse
import collections
import os
import sys

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import sudoku_ocr as so


def parse_ids(spec):
    if "-" in spec:
        a, b = spec.split("-")
        return [str(i) for i in range(int(a), int(b) + 1)]
    return spec.split(",")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pages", nargs="+", metavar="PHOTO:IDS")
    ap.add_argument("--tag", required=True, help="font tag, e.g. the publication name")
    ap.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270])
    ap.add_argument("--corpus", default="corpus/magazine.json")
    args = ap.parse_args()

    import json
    corpus = {m["id"]: m["puzzle"] for m in json.load(open(args.corpus))}

    samples = collections.defaultdict(list)
    for spec in args.pages:
        path, _, ids = spec.rpartition(":")
        puzzles = [corpus[i] for i in parse_ids(ids)]
        gray = cv2.cvtColor(so.load(path, args.rotate), cv2.COLOR_BGR2GRAY)
        quads = so.find_grids(gray)
        print(f"{path}: {len(quads)} grids for {len(puzzles)} corpus entries")
        for q in quads:
            thr = so.grid_threshold(so.warp(gray, q))
            fm = [so.cell_mask(thr, r, c) is not None for r in range(9) for c in range(9)]
            truth = min(puzzles, key=lambda p: sum((ch != '.') != f for ch, f in zip(p, fm)))
            mismatch = sum((ch != '.') != f for ch, f in zip(truth, fm))
            if mismatch > 5:
                print(f"  grid skipped: no corpus match (best mismatch {mismatch})")
                continue
            for k in range(81):
                if truth[k] == ".":
                    continue
                mask = so.cell_mask(thr, k // 9, k % 9)
                if mask is not None:
                    samples[truth[k]].append(so.norm_digit(mask))

    existing = {}
    if os.path.exists(so.TEMPLATE_FILE):
        data = np.load(so.TEMPLATE_FILE)
        existing = {k: data[k] for k in data.files
                    if ":" in k and k.split(":")[1] != args.tag}
    for d, xs in sorted(samples.items()):
        existing[f"{d}:{args.tag}"] = np.mean(xs, axis=0)
        print(f"  {d}: {len(xs)} samples")
    np.savez(so.TEMPLATE_FILE, **existing)
    print(f"saved {len(existing)} templates to {so.TEMPLATE_FILE}")


if __name__ == "__main__":
    main()
