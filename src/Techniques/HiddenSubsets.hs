module Techniques.HiddenSubsets (hiddenSubsets, hiddenSingles) where

import Board
import qualified Data.IntSet as IntSet
import Data.Maybe (mapMaybe)
import Grid
import Technique

-- | All hidden subsets of size n: a value-set s whose open homes number
--   exactly n means those cells can hold nothing but s -> shrink them to s.
hiddenSubsets :: SubsetSize -> Technique
hiddenSubsets n = onGroups (hiddenInGroup n)

-- | A hidden single is a hidden subset of size 1.
hiddenSingles :: Technique
hiddenSingles = hiddenSubsets 1

hiddenInGroup :: SubsetSize -> [CellInfo] -> [Finding]
hiddenInGroup n cells = mapMaybe (hiddenSubsetAt n open) (valueSets n open)
  where
    open = filter (isPossibleValues . cellInfoCell) cells

-- | The finding for value-set s over these open cells, if s is hidden here
--   and shrinking its homes changes anything.
hiddenSubsetAt :: SubsetSize -> [CellInfo] -> Candidates -> Maybe Finding
hiddenSubsetAt n open s
  | length homes == n, not (null updates) =
      Just (Finding (HiddenSubset n) updates (map cellInfoIndex homes))
  | otherwise = Nothing
  where
    homes = filter (overlaps s . cellInfoCell) open
    updates = mapMaybe (\ci -> eliminateTo (cellInfoIndex ci) (cellInfoCell ci) s) homes

overlaps :: Candidates -> Cell -> Bool
overlaps s c = not (IntSet.disjoint s (cellCandidates c))
