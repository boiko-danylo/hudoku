module Techniques.PeerElimination (peerElimination) where

import Board
import qualified Data.IntSet as IntSet
import Data.List (partition)
import Data.Maybe (mapMaybe)
import Grid
import Technique

-- | Ban every solved value in a group from the group's open cells.
peerElimination :: Technique
peerElimination = onGroups eliminateSolved

-- | At most one finding per group; witnesses are the solved cells.
eliminateSolved :: [CellInfo] -> [Finding]
eliminateSolved cells =
  [Finding PeerElimination updates (map cellInfoIndex solved) | not (null updates)]
  where
    (solved, open) = partition (isCellValue . cellInfoCell) cells
    banned = IntSet.fromList (map (cellValue . cellInfoCell) solved)
    updates = mapMaybe (\ci -> eliminateFrom (cellInfoIndex ci) (cellInfoCell ci) banned) open
