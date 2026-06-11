module TestBoard1d where

import Board
import qualified Data.IntSet as IntSet

-- | A one-dimensional board: n cells forming a single all-different group.
lineBoard :: Int -> Board
lineBoard n =
  Board
    { boardSize = n,
      boardCellCount = n,
      boardGroups = [Group AllDifferent (IntSet.fromList [0 .. n - 1])]
    }

testBoard1dSize = 5

testBoard1d = lineBoard testBoard1dSize
