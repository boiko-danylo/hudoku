# ADR-0007: Hypergraph implementation shape

Date: 2026-06-11
Status: Accepted

Realizes ADR-0002 (hypergraph core) and ADR-0003 (constraint layer) in one
coordinated migration, since both reshape `Group`.

## Context

Techniques only ever consume cell identity and group membership, yet every
group access translates coordinates through `posToNum`'s linear search.
ADR-0002 settled that the core is a hypergraph; ADR-0003 that groups carry
a constraint kind. What remained was the concrete shape, and where
geometry goes afterwards.

## Decision

Core types:

```haskell
data Constraint = AllDifferent            -- grows Sum, relations, ... later

data Group = Group
  { groupConstraint :: Constraint
  , groupCells      :: IntSet }           -- hyperedge: a SET of GridIndex

data Board = Board
  { boardSize      :: Size                -- value domain 1..size
  , boardCellCount :: Int                 -- vertices; NOT derivable from size (samurai)
  , boardGroups    :: [Group] }

type CellInfo = (GridIndex, Cell)
cellsOf :: Grid -> Group -> [CellInfo]    -- replaces groupToCellInfo/posToNum
```

- Group cells are an `IntSet`: a group *is* a set (no order, no
  duplicates); membership/intersection are cheap for future techniques
  (peers, generalized fish). Iteration is deterministic via ascending
  order.
- `Position`, `PositionList`, `posToNum`, `posToCell`, `Dimensions` are
  deleted from the core. Geometry is construction scaffolding: a
  constructor computes groups from coordinates, converts to indexes, and
  discards the coordinates.
- Presentation context lives in a new **Variant** layer (owner's design):

```haskell
data Layout  = Layout2D { layoutWidth :: Size, layoutHeight :: Size }
                                          -- row-major; 3D/irregular = new constructors
data Variant = Variant { variantBoard :: Board, variantLayout :: Layout }
```

  A `Variant` bundles everything a UI needs (board + geometry + future
  rules metadata); renderers consume `Variant`, never `Board` alone.
  `classicVariant = Variant classicBoard (Layout2D 9 9)`.
- `readGridFor` additionally validates input length against
  `boardCellCount`.

## Consequences

- The `posToNum` linear-search debt dissolves; group scans index directly.
- Variant support = writing a group generator (+ a `Layout` if a new shape).
- `GridShowers` renders via `Variant`; `Show Board` is derived, structural
  assertions replace the old string test.
- Techniques are untouched except for the narrower `CellInfo` — evidence
  the abstraction was already honest.
