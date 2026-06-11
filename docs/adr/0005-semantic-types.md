# ADR-0005: Semantic types for domain quantities

Date: 2026-06-11
Status: Implemented (2026-06-11)

## Context

Domain quantities appear in signatures as bare `Int`: a cell's value, a
grid index, a group index, a subset size. The reader can't tell which
`Int` is which, and a future change of value representation (letters for
16×16 boards, hex display, …) would mean hunting raw `Int`s across the
codebase.

## Decision

Every domain quantity gets a named type; bare `Int`/`IntSet` must not
appear in exported signatures. Starting set:

```haskell
type Value      = Int     -- what a cell can hold (1..n today)
type GridIndex  = Int     -- cell identity in the grid
type GroupIndex = Int     -- group identity on the board
type Candidates = IntSet  -- a set of Values (rename of CellPossibleValues)
```

Notes:

- `type` aliases are documentation and a single point of change — the
  compiler does *not* stop you mixing a `Value` with a `GridIndex` (both
  are `Int`). When that class of bug actually bites, the upgrade path is
  `newtype` (compiler-enforced, zero runtime cost); we start with aliases
  to keep code friction low while learning.
- `Candidates = IntSet` ties candidate sets to `Int` values. If `Value`
  ever stops being `Int`, this becomes `Set Value` — one definition to
  change, which is the point.
- Display format (letters, hex) is a **renderer** concern: values can stay
  `Int` internally and render however the UI wants. A representation
  change is only needed if the *domain* stops being order-isomorphic to
  small integers.

## Consequences

- Signatures become self-describing (`SubsetSize`, already present, is the
  pattern to follow).
- Renames touch `Grid.hs`/`Board.hs` widely but mechanically.
- Revisit `newtype` per quantity when a mixup bug or a real representation
  change shows up — record it as a new ADR then.
