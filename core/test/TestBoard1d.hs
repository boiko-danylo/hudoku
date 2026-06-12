module TestBoard1d where

import Board
import qualified Data.IntSet as IntSet

-- | A one-dimensional board: n cells over n values forming a single
--   group — a Permutation, every value must appear.
lineBoard :: Int -> Board
lineBoard n =
  Board
    { boardSize = n,
      boardCellCount = n,
      boardGroups = [Group Permutation (IntSet.fromList [0 .. n - 1])]
    }

testBoard1dSize = 5

testBoard1d = lineBoard testBoard1dSize
