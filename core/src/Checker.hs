module Checker where

import Board
import Data.List (group, sort)
import Grid

-- | A grid is correct when no group repeats a solved value.
isBoardCorrect :: Board -> Grid -> Bool
isBoardCorrect b g = all groupCorrect (boardGroups b)
  where
    groupCorrect grp = distinct (solvedValues grp)
    solvedValues grp = map cellValue (filter isCellValue (map cellInfoCell (cellsOf g grp)))
    distinct xs = all ((== 1) . length) (group (sort xs))
