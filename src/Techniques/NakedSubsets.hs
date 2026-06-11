module Techniques.NakedSubsets
  ( nakedSubsets,
    -- internals exported for piecewise testing
    findInGroup,
    valueSets,
    nakedSubsetAt,
  )
where

import Board
import qualified Data.IntSet as IntSet
import Data.List (partition, subsequences)
import Data.Maybe (mapMaybe)
import Grid
import Technique

-- | All naked subsets of size n, across all groups of the board.
nakedSubsets :: SubsetSize -> Technique
nakedSubsets n board grid =
  concatMap (findInGroup n . groupToCellInfo board grid) (boardGroups board)

findInGroup :: SubsetSize -> [CellInfo] -> [Finding]
findInGroup n cells = mapMaybe (nakedSubsetAt n open) (valueSets n open)
  where
    open = filter (isPossibleValues . cellInfoCell) cells

-- | All value-sets of size n drawn from the open cells' candidates.
valueSets :: SubsetSize -> [CellInfo] -> [Candidates]
valueSets n open =
  [ IntSet.fromList vs
    | vs <- subsequences (IntSet.toList groupValues),
      length vs == n
  ]
  where
    groupValues = IntSet.unions (map (cellCandidates . cellInfoCell) open)

-- | The finding for value-set s over these open cells, if s is naked here
--   and eliminating it changes anything.
nakedSubsetAt :: SubsetSize -> [CellInfo] -> Candidates -> Maybe Finding
nakedSubsetAt n open s
  | length members == n, not (null updates) =
      Just (Finding NakedSubset updates (map cellInfoIndex members))
  | otherwise = Nothing
  where
    (members, others) =
      partition ((`IntSet.isSubsetOf` s) . cellCandidates . cellInfoCell) open
    updates =
      mapMaybe (\ci -> eliminateFrom (cellInfoIndex ci) (cellInfoCell ci) s) others
