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
| **Board** | The structure: cells + constrained groups. Core model is a hypergraph (ADR-0002). |
| **Group** | A set of cells plus a constraint kind; AllDifferent only, for now (ADR-0003). |
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
  board constructors and UI/renderers. *(Accepted; implementation deferred
  while the owner studies the framing.)*
- **ADR-0003** — Groups carry a constraint kind; AllDifferent is the only
  implementation for now, variants (killer, kropki, …) extend it later.
- **ADR-0004** — Remove `EmptyCellVallue`; empty = full candidate set;
  `Cell` becomes two-state and total.
- **ADR-0005** — Semantic types for domain quantities (`Value`, `GridIndex`,
  `Candidates`, …); no bare `Int` in exported signatures; display format is a
  renderer concern.

## Open questions

- **Monad shape of the solver.** Pure techniques make the solver the monadic
  part (Reader Board + State Grid + Writer Steps ≈ RWS). mtl-style classes vs
  a concrete stack is undecided — and is itself a learning goal (monads,
  applicatives, monoids…). Decide by building both on a small slice.
- **Given vs Solved cells.** Distinguish clue cells from derived values for
  rendering/generation? (Deferred in ADR-0004.)
- **Hypergraph refactor timing.** ADR-0002 is accepted but parked; new code
  should at least not deepen coupling to `Position` coordinates.

## Current state (2026-06)

- `Board` = dimensions + size + `[Group]` + position list; `Position = [Int]`
  (predates ADR-0002/0003).
- `Grid = [Cell]`, `Cell = CellValue | EmptyCellVallue | PossibleValues IntSet`
  (predates ADR-0004).
- `Game` monad = `StateT Grid (ReaderT Board Identity)`; migration from pure
  pipeline style is in progress (`Main.hs` is a scratchpad).
- Techniques: candidate elimination + unique-in-group (`Board.hs`),
  hidden subsets (pure style), naked subsets (monadic style, incomplete) —
  all predating the ADR-0001 contract.
- `Steps` module is scaffolding for explainable solutions — not wired up yet.

## Known debt

- `posToNum` is a linear search; `Grid` is a list indexed with `!!`.
  Candidates for `Vector` / `IntMap` (also a learning topic; partly dissolves
  under ADR-0002).
- Typos baked into constructors: `EmptyCellVallue` (ADR-0004), `NackedSet`
  (ADR-0001 rename).
- No real CLI despite README; `Main.hs` needs replacing once a solver exists.
- `initPossibleValues'` marked for deprecation (dissolves under ADR-0004);
  `removeCandidates` untested.
