module Checker where

import Board
-- import Data.Maybe
import Data.List
import Grid

-- TODO: Cover
isBoardCorrect :: Board -> Grid -> Bool
isBoardCorrect b g = all groupCorrect $ boardGroups b
  where
    groupCorrect :: Group -> Bool
    groupCorrect g = foldl (\c (val, freq) -> c && freq == 1) True $ groupFreq g

    groupFreq :: Group -> [(Value, Int)]
    groupFreq g = map (\x -> (head x, length x)) . group . sort . map cellValue $ values g
    values :: Group -> [Cell]
    values g = filter isCellValue $ map cell g
    cell :: Position -> Cell
    cell = posToCell b g
