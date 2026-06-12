# Hudoku

[![CI](https://github.com/boiko-danylo/hudoku/actions/workflows/ci.yml/badge.svg)](https://github.com/boiko-danylo/hudoku/actions/workflows/ci.yml)

A structure-based sudoku solver — a monorepo growing from a Haskell core.

Boards are generic structures (cells + constrained groups) — the classic
9×9 grid is just one instance. Techniques are pure finders returning
explainable `Finding`s; a solver applies them one at a time and journals
every step. See `DESIGN.md` and `docs/adr/` for the architecture and the
decisions behind it.

## Layout

| Directory | What it is |
|-----------|------------|
| `core/`   | `hudoku-core`: the Haskell solver library, example executable, tests |
| `corpus/` | Ground-truth puzzles from photographed magazines, shared by core tests and OCR tuning; `verify.hs` checks transcriptions |
| `ocr/`    | Python/OpenCV pipeline: page photo → grids → 81-char puzzle strings, plus the live webcam viewer |
| `docs/adr/` | Architecture decision records; ADR-0008 is the monorepo roadmap |

Planned subprojects (see ADR-0008): `protocol`, `libhudoku` (C ABI),
`wasm`, `cli`, `api`, `spa`, `gui`, `ios`.

## Build & test

```sh
stack build
stack test
stack exec exe   # solve the built-in example grid
```
