# ADR-0001: Technique / Finding / Solver contract

Date: 2026-06-11
Status: Accepted

## Context

The modules under `src/Algs/` mix three responsibilities: scanning the grid
for a pattern, applying the resulting changes, and (half-built) describing
them as strings. The name "Alg" is also wrong — these are solving
*techniques*. `findNakedSubsetsNSteps` was sketched as `Game Steps`
(monadic, self-applying, string-building), and the question of
`Maybe [Step]` vs `[Step]` was open.

## Decision

Fix the terminology and the contract:

- **Technique** (replaces "Alg"): a *pure* finder.

  ```haskell
  technique :: Board -> Grid -> [Finding]
  ```

  Given the current state it returns **all** findings applicable to that
  state. An empty list means "nothing found" — no `Maybe` (a `Nothing`
  distinct from `[]` carries no meaning here).

- **Finding**: pure data, no strings, no grid. It must be applicable later
  by generic machinery, and useful for UI:
  - which technique produced it (tag),
  - the cell updates: positions + new cell values/candidates,
  - the involved cells (the pattern's witnesses, for highlighting/UI).

  Human-readable descriptions are *rendered from* a Finding by a separate
  function, never built inside a technique.

- **Solver**: the driver. It owns application policy — apply one finding and
  re-scan, batch, choose technique order — so findings do not need to be
  conflict-free among themselves. Solvers are values we can compose and
  combine; this is the future hook for puzzle-difficulty detection and
  puzzle generation.

## Consequences

- Techniques stay trivially testable (pure in, data out).
- One generic `apply :: Grid -> Finding -> Grid` replaces per-technique
  application code.
- `Steps`/explanations become a rendering concern over applied Findings.
- Existing `Algs.*` modules will be renamed and reshaped to this contract
  (including fixing the `NackedSet` typo).
