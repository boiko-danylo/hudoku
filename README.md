# Hudoku

[![CI](https://github.com/boiko-danylo/hudoku/actions/workflows/ci.yml/badge.svg)](https://github.com/boiko-danylo/hudoku/actions/workflows/ci.yml)

A structure-based sudoku solver written in Haskell.

Boards are generic structures (cells + constrained groups) — the classic
9×9 grid is just one instance. Techniques are pure finders returning
explainable `Finding`s; a solver applies them one at a time and journals
every step. See `DESIGN.md` and `docs/adr/` for the architecture and the
decisions behind it.

## Build & test

```sh
stack build
stack test
stack exec exe   # solve the built-in example grid
```
