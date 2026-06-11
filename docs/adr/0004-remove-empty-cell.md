# ADR-0004: Remove EmptyCellVallue

Date: 2026-06-11
Status: Accepted

## Context

`Cell` has three states: `CellValue Int`, `PossibleValues IntSet`, and
`EmptyCellVallue`. The empty state exists only as a pre-initialization
placeholder, and it is the source of partial functions and runtime errors
(`error "init values before update"` in `updatePossibleValues`,
`cellCandidates` blowing up on non-candidate cells). Semantically an empty
cell *is* a cell whose candidates are the full domain.

## Decision

Remove `EmptyCellVallue` (typo and all). An unsolved cell with no
information is `PossibleValues fullDomain`; board/grid construction
produces candidate cells directly instead of placeholders that must be
initialized later.

## Consequences

- `Cell` becomes two-state: solved value or candidate set. Every
  `case`/guard over cells becomes total; the "init before update" error
  class disappears.
- `readGrid`, `initPossibleValues'` and friends fold initialization into
  construction; the deprecated post-init step goes away.
- Open (deliberately not decided here): whether to split solved cells into
  `Given` (clue) vs `Solved` (derived) — useful for rendering and for
  puzzle generation later. Revisit when the UI layer takes shape.
