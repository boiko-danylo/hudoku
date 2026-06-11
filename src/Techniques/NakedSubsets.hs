module Techniques.NakedSubsets
  ( nakedSubsets,
    -- internals exported for piecewise testing
    findInGroup,
    nakedSubsetAt,
  )
where

import Board
import qualified Data.IntSet as IntSet
import Data.List (partition)
import Data.Maybe (mapMaybe)
import Grid
import Technique

-- | All naked subsets of size n: exactly n cells confined to a value-set s
--   of size n must consume s among themselves -> eliminate s from the rest
--   of the group.
nakedSubsets :: SubsetSize -> Technique
nakedSubsets n = onGroups (findInGroup n)

findInGroup :: SubsetSize -> [CellInfo] -> [Finding]
findInGroup n cells = mapMaybe (nakedSubsetAt n open) (valueSets n open)
  where
    open = filter (isPossibleValues . cellInfoCell) cells

-- | The finding for value-set s over these open cells, if s is naked here
--   and eliminating it changes anything.
nakedSubsetAt :: SubsetSize -> [CellInfo] -> Candidates -> Maybe Finding
nakedSubsetAt n open s
  | length members == n, not (null updates) =
      Just (Finding (NakedSubset n) updates (map cellInfoIndex members))
  | otherwise = Nothing
  where
    (members, others) =
      partition ((`IntSet.isSubsetOf` s) . cellCandidates . cellInfoCell) open
    updates =
      mapMaybe (\ci -> eliminateFrom (cellInfoIndex ci) (cellInfoCell ci) s) others
