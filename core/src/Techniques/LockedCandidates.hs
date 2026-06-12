module Techniques.LockedCandidates (lockedCandidates) where

import Board
import qualified Data.IntSet as IntSet
import Data.Maybe (mapMaybe)
import Grid
import Technique

-- | One rule covering both "pointing" and "claiming": for groups A and B
--   sharing cells I, a value whose only homes in A lie inside I must land
--   in I — so it is impossible in B \ I. No geometry: any two overlapping
--   groups qualify, which is what makes this work on variants for free.
--
--   The prover A must guarantee every value appears in it (Permutation,
--   by evidence — ADR-0010). The receiver B needs no such strength.
lockedCandidates :: Technique
lockedCandidates board grid =
  [ Finding LockedCandidates updates (map cellInfoIndex homes)
    | (a, b) <- orderedPairs,
      let shared = groupCells a `IntSet.intersection` groupCells b,
      -- a single shared cell would make this a hidden single in disguise
      IntSet.size shared >= 2,
      v <- IntSet.toList (openCandidates (cellsAt shared)),
      let homes = filter (canHold v) (openCellsOf a),
      -- "all homes inside I" is vacuously true when v has no homes left
      not (null homes),
      all ((`IntSet.member` shared) . cellInfoIndex) homes,
      let outside = cellsAt (groupCells b `IntSet.difference` shared),
      let updates = mapMaybe (banFrom v) outside,
      not (null updates)
  ]
  where
    orderedPairs =
      [ (permutationGroup pa, b)
        | pa <- permutationGroups board,
          b <- boardGroups board,
          groupCells (permutationGroup pa) /= groupCells b
      ]
    cellsAt ix = map (\i -> (i, grid !! i)) (IntSet.toAscList ix)
    openCellsOf g = filter (isPossibleValues . cellInfoCell) (cellsOf grid g)
    openCandidates cells = IntSet.unions [cs | (_, PossibleValues cs) <- cells]
    canHold v = IntSet.member v . cellCandidates . cellInfoCell
    banFrom v (i, cell) = eliminateFrom i cell (IntSet.singleton v)
