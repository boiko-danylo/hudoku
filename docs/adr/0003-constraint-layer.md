# ADR-0003: Groups carry a constraint kind (all-different first)

Date: 2026-06-11
Status: Implemented (2026-06-11, shape in ADR-0007; AllDifferent only)

## Context

Every current technique silently assumes a group means "these cells hold
pairwise different values". That covers classic sudoku and many variants
(jigsaw, hyper, multi-grid combos — they differ only in group sets). It
does **not** cover killer cages (sum constraints), kropki dots,
thermometers, or anti-knight rules, which constrain cells in other ways.
The project's vision is to support variants fundamentally.

## Decision

Introduce a **constraint level** in the core: a group is *cells + a
constraint kind*, not bare cells.

- The first and, for now, only constraint kind is **AllDifferent**.
- Techniques declare which constraint kinds they understand and only
  receive groups they can handle (a naked-subset technique asks for
  AllDifferent groups; a future killer technique asks for Sum groups).
- Constraint kinds are modeled so that adding one (e.g. `Sum Int`) extends
  the data type without touching existing techniques.

## Consequences

- `Group = [Position]` becomes a structure with a constraint tag; board
  constructors tag everything `AllDifferent` today.
- Existing techniques gain an explicit, honest statement of their
  assumption instead of an implicit one.
- Variant constraints later (killer, kropki, thermo, anti-knight) are an
  extension, not a redesign.
- Slightly more ceremony now for no behavioral change — accepted as the
  price of the vision.
