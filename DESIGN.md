# Hudoku — Design Notes

## Vision

Hudoku is not a 9×9 sudoku solver. It is a **general structure-based puzzle solver**:

1. **Board = structure.** A board describes cells and their connections: groups,
   graphs, cell relations. The classic 9×9 grid is just one instance. The design
   must accommodate multiple dimensions, different sizes, variants, and
   combinations of variants. (`ClassicBoard` is one constructor among many.)

2. **Techniques operate on structure.** Given a `Board`, solving logic works
   mostly through groups — mappings between cells, candidates, and groups —
   never through hardcoded geometry.

3. **Technique ≠ usage.** A technique *finds*; a solver decides what to apply,
   in what order, and how to present it.

4. **Educational project.** The point is learning Haskell — its libraries,
   idioms, and ways of structuring programs. Idiomatic design is a first-class
   goal; "it works" is not enough.

## Terminology

| Term | Meaning |
|---|---|
| **Board** | The structure: a hypergraph — cells (`GridIndex` vertices) + constrained groups (ADR-0002/0007). |
| **Group** | A constraint kind + an `IntSet` of cells (hyperedge); AllDifferent only, for now (ADR-0003/0007). |
| **Technique** | A pure finder, `Board -> Grid -> [Finding]`, returning **all** findings applicable in the current state; `[]` = none (ADR-0001). Replaces the old name "Alg". |
| **Finding** | Pure data produced by a technique: technique tag, cell updates (position + new cell, applicable later by a generic `apply`), involved cells for UI. No strings, no grid (ADR-0001). |
| **Solver** | The driver: chooses techniques, applies findings (e.g. apply-one-and-rescan), records steps. Solvers compose; future hook for difficulty grading and puzzle generation (ADR-0001). |
| **Step** | The record of an applied Finding — the unit of an explainable solution. |

Descriptions for humans are *rendered from* Findings/Steps, never built
inside techniques.

## Decisions (see docs/adr/)

- **ADR-0001** — Technique/Finding/Solver contract: pure techniques, data
  findings, list not `Maybe`, application policy belongs to solvers.
- **ADR-0002** — Board core is a hypergraph; coordinates/geometry only in
  board constructors and the Variant layer. *(Implemented via ADR-0007.)*
- **ADR-0003** — Groups carry a constraint kind; AllDifferent is the only
  implementation for now, variants (killer, kropki, …) extend it later.
- **ADR-0004** — Remove `EmptyCellVallue`; empty = full candidate set;
  `Cell` becomes two-state and total.
- **ADR-0005** — Semantic types for domain quantities (`Value`, `GridIndex`,
  `Candidates`, …); no bare `Int` in exported signatures; display format is a
  renderer concern.
- **ADR-0006** — Findings carry instructions/deltas (`Eliminate`/`Place`),
  not result cells; event-sourcing style, batch application safe.
- **ADR-0007** — Hypergraph implementation shape: `Group` = constraint +
  `IntSet`, `Board` record, `CellInfo = (GridIndex, Cell)`, geometry in the
  `Variant` layer (`Board` + `Layout`), `Position` deleted.

## Open questions

- **Monad shape of the solver.** Pure techniques make the solver the monadic
  part (Reader Board + State Grid + Writer Steps ≈ RWS). mtl-style classes vs
  a concrete stack is undecided — and is itself a learning goal (monads,
  applicatives, monoids…). Decide by building both on a small slice.
- **Given vs Solved cells.** Distinguish clue cells from derived values for
  rendering/generation? (Deferred in ADR-0004.)
- **Variant layer growth.** `Variant` currently bundles board + 2D layout;
  rules metadata and richer layouts (3D, irregular) join when a UI or a
  non-classic variant demands them.

## Current state (2026-06, post-migration)

- The ADR-0001 pipeline is live end to end: `Technique → [Finding] →
  Solver (RWS) → journal`. `runSolver standardTechniques` solves real
  puzzles (see the end-to-end group in `test/Spec.hs`); `Main.hs` runs it.
- Techniques (one module each under `Techniques/`): `peerElimination`,
  `nakedSingles`, `nakedSubsets n`, `hiddenSubsets n`;
  `hiddenSingles = hiddenSubsets 1` (partial application, tagged
  `HiddenSubset 1`). Family combinator: `Technique.onGroups`.
- `TechniqueId` carries the subset size — the journal doubles as a
  difficulty record.
- All pre-ADR solving code is gone (`Algs/*`, `Steps`,
  `updatePossibleValues`, `updateUniqueValues`, `updateGridWithValues`,
  `refreshGridValues`, `recursiveUpdateWith`); scenarios were ported to the
  new tests first.
- ADR-0004 and ADR-0005 are implemented: two-state `Cell`, board-aware
  `readGridFor`, semantic types throughout; `Game.hs` is gone.
- ADR-0002/0003/0007 are implemented: `Board` is a pure hypergraph
  (`Group AllDifferent <IntSet>`), `Position` is gone, geometry lives in
  constructors and the `Variant` layer (`classicVariant`).

## Known debt

- `Grid` is a list indexed with `!!`/`splitAt` — fine at 81 cells; switch to
  `Vector` when profiling says so (a learning topic on its own).
- `Main.hs` solves a hardcoded grid; reading from stdin/args still to do.
- Description renderer for Findings (UI layer) not started.
- `test/Missions/` + `hard.json`: dormant sudoku.com puzzle corpus (with
  solutions) — revive as an end-to-end test pack when useful.
