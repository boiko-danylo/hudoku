# ADR-0010: Constraint strength and technique requirements

Status: Accepted (2026-06-12)

## Context

Techniques have soundness premises, and they are not uniform. Naked
subsets and peer elimination need only "no two cells equal". Hidden
subsets and the locked-candidates prover need more: "every domain value
appears in this group" — true for a 9-cell group over 9 values
(pigeonhole), false in general (a killer cage is all-different without
containing every value). Before this ADR the codebase handled this by
luck and by a size-arithmetic guard inside `lockedCandidates`; ADR-0003
gave groups a constraint kind but only one (`AllDifferent`), too weak to
express the distinction. The user also wants the inverse question
answerable: which techniques apply to a given board/game — for the
driver today, for UI menus, difficulty grading and a technique trainer
later.

A full type-level encoding (DataKinds/GADTs/singletons) was considered
and rejected for now: boards are runtime data (corpus JSON, OCR,
generators), so constraint strength is runtime information; type-level
machinery would only move the runtime check behind heavy ceremony. GADT
board kinds remain a designated future option when a consumer needs
statically-known variants.

## Decision

Three layers, each at the weight its job needs:

1. **Vocabulary (values).** `Constraint = AllDifferent | Permutation`
   with entailment `implies :: Constraint -> Constraint -> Bool`
   (`Permutation` implies `AllDifferent`). Boards declare strength:
   classic groups are `Permutation`. Future kinds (e.g. `Sum` for
   killer cages) extend the data type and the entailment table.

2. **Evidence (types) — "parse, don't validate".** The premise check
   happens once, at a boundary, and its success is carried as a type:
   `PermutationGroup` is a newtype whose constructor is not exported;
   `permutationGroups :: Board -> [PermutationGroup]` is the only way
   to obtain one. Technique code paths that need the strong premise
   (`onPermutationGroups`, the locked-candidates prover) consume the
   evidence type, so a technique author *cannot* skip the check — GHC
   enforces it. `onGroups` filters to groups entailing `AllDifferent`.

3. **Advertisement (values).** `TechniqueDef { techId, techNeeds ::
   [Constraint], techRun }` makes techniques inspectable.
   `applicable :: Board -> [TechniqueDef] -> [TechniqueDef]` filters by
   premises; `standardTechniques` is now a catalog of defs and
   `runSolver` selects what fits the board before running. techNeeds is
   deliberately a flat list (option B1): since soundness lives in layer
   2, over-generous advertisement is harmless (a technique runs and
   finds nothing). A richer requirement language (per-role strengths,
   "two overlapping groups" — option B2) is the planned evolution,
   triggered by the first technique with a relational premise or the
   first consumer needing per-variant precision.

## Consequences

- `hiddenSubsets` is now incapable of firing on a non-Permutation
  group — previously it was unsound-in-principle there and correct
  only because no such group existed. The `lockedCandidates`
  size-arithmetic guard is replaced by evidence.
- `Board.hs` gains an export list (required to hide the evidence
  constructor).
- Call sites of `runSolver standardTechniques board grid` are unchanged
  in shape; only the type behind `standardTechniques` changed
  (`[TechniqueDef]`). The engine-level `runSolverWith :: [Technique] ->
  ...` remains for tests and custom drivers.
- The catalog is the natural API surface for the planned frontends
  (technique lists per game type, trainer mode): ids, premises and
  runners in one queryable value.
- Known gap, deliberately left: `groupSolved` checks "cells are a
  permutation of 1..n", which is the `Permutation` semantics; when the
  first truly weak group arrives (killer cages), solvedness must
  become constraint-aware. Same trigger as the `Sum` constraint.
