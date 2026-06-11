# ADR-0006: Findings carry instructions (deltas), not result cells

Date: 2026-06-11
Status: Accepted

## Context

ADR-0001 says a Finding holds "cell updates" without fixing their
representation. Two candidates were considered:

- **Absolute**: store the resulting cell (`(GridIndex, Cell)`); apply =
  replace.
- **Delta**: store the change itself (`Eliminate index candidates` /
  `Place index value`).

A Finding is computed at find-time but executed at apply-time, possibly
after sibling findings have changed the grid. Absolute cells bake a
snapshot into the Finding: applying two findings that touch the same cell
makes the second one resurrect candidates the first removed (last write
wins). Replacement can be repaired by intersecting with the current cell,
but then the stored cell no longer means what it says — it becomes a
delta encoded as a result, with the real semantics hidden in `apply`.

## Decision

Findings store **instructions**, event-sourcing style:

```haskell
data CellUpdate
  = Eliminate GridIndex Candidates  -- remove these candidates from this cell
  | Place     GridIndex Value       -- this cell becomes this value
```

`apply` executes instructions against the *current* grid. Independent
eliminations commute, so a solver may apply a whole batch from one
snapshot in any order, or one-at-a-time and rescan — its choice, per
ADR-0001.

## Consequences

- Batch application is safe; the Finding representation does not secretly
  force an application policy.
- A `Step` log renders directly ("removed 4,7 from cell 31") with no
  diffing against a grid that has since moved.
- The delta is constructed at find-time by a diff helper (candidates
  before vs candidates the pattern allows); techniques that find nothing
  to remove produce no update.
- A future kind of change (beyond eliminate/place) extends `CellUpdate`.
