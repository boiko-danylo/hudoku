# ADR-0002: Board core is a hypergraph; geometry lives at the edges

Date: 2026-06-11
Status: Accepted (implementation deferred — owner studying the topic)

## Context

`Board` currently carries dimensions, size, groups, and a
`PositionList` mapping grid indices to `Position [Int]` coordinates.
Techniques, however, only ever need *cell identity* and *group
membership* — none of them care where a cell sits geometrically.
Meanwhile the vision explicitly includes multi-dimensional boards,
different sizes, variants, and combinations of variants.

## Decision

The core board model is a **hypergraph**: cells are vertices (plain
indices), groups are hyperedges. Coordinates and dimensionality are *not*
part of the core. They belong to:

- **Board constructors** — geometry is how a constructor *generates* the
  groups (rows/columns/boxes for classic, irregular regions for jigsaw,
  overlapping grids for samurai, 3D adjacency for cubes), after which it
  is discarded from the solving core;
- **Renderers / UI** — a human-facing shape will be reintroduced at the UI
  layer, as a mapping from cell index to display coordinates, separate
  from solving.

Under this model, "variant support" for any all-different variant is just
a different group generator — zero changes to techniques or solvers.

## Consequences

- `Position [Int]` and `PositionList` leave the core types; techniques and
  Findings refer to cells by index.
- Lookup helpers like `posToNum` (currently a linear search) disappear or
  move to the constructor/UI boundary.
- A later UI ADR must define the index → display-coordinates mapping.
- Not implemented yet: owner wants to study hypergraph framing first; the
  decision is recorded so new code does not deepen the coupling to
  coordinates.
