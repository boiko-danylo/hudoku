module ClassicBoard where

import Board
import qualified Data.IntSet as IntSet
import Grid
import Variant

-- Geometry is construction scaffolding (ADR-0007): rows, columns and
-- boxes are computed from (x, y) coordinates, converted to indexes, and
-- the coordinates are discarded.
classicBoard :: Board
classicBoard =
  Board
    { boardSize = 9,
      boardCellCount = 81,
      boardGroups = map (Group AllDifferent . IntSet.fromList) (rows ++ cols ++ boxes)
    }
  where
    idx x y = (y - 1) * 9 + (x - 1)
    rows = [[idx x y | x <- [1 .. 9]] | y <- [1 .. 9]]
    cols = [[idx x y | y <- [1 .. 9]] | x <- [1 .. 9]]
    boxes = [[idx (bx + dx) (by + dy) | dy <- [1 .. 3], dx <- [1 .. 3]] | by <- [0, 3, 6], bx <- [0, 3, 6]]

classicVariant :: Variant
classicVariant = Variant classicBoard (Layout2D 9 9)

readClassicGrid :: String -> Maybe Grid
readClassicGrid = readGridFor classicBoard
