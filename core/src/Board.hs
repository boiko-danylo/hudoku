module Board where

import Data.Char (digitToInt, isDigit)
import Data.IntSet (IntSet)
import qualified Data.IntSet as IntSet
import Data.Ix (range)
import Data.List (sort)
import Grid

-- ADR-0002/0007: the board is a hypergraph. Cells are vertices identified
-- by GridIndex; groups are hyperedges. Geometry exists only inside board
-- constructors (and the Variant layer) — never here.

type Size = Int

type GridIndex = Int

-- ADR-0003: what a group demands of its cells
data Constraint = AllDifferent
  deriving (Show, Eq)

data Group = Group
  { groupConstraint :: Constraint,
    groupCells :: IntSet
  }
  deriving (Show, Eq)

data Board = Board
  { boardSize :: Size, -- value domain 1..size
    boardCellCount :: Int, -- vertices; not derivable from size (samurai: 369 cells, size 9)
    boardGroups :: [Group]
  }
  deriving (Show)

boardValues :: Board -> Candidates
boardValues board = IntSet.fromList (range (1, boardSize board))

type CellInfo = (GridIndex, Cell)

cellInfoIndex :: CellInfo -> GridIndex
cellInfoIndex = fst

cellInfoCell :: CellInfo -> Cell
cellInfoCell = snd

-- | A group's cells paired with their identity, in ascending index order.
cellsOf :: Grid -> Group -> [CellInfo]
cellsOf grid g = map (\i -> (i, grid !! i)) (IntSet.toAscList (groupCells g))

-- | Parse a grid for this board: '.' and '0' are open cells carrying the
--   board's full domain as candidates (ADR-0004). The input must describe
--   exactly the board's cells.
readGridFor :: Board -> String -> Maybe Grid
readGridFor board s
  | length s /= boardCellCount board = Nothing
  | otherwise = traverse readCell s
  where
    open = PossibleValues (boardValues board)
    readCell '.' = Just open
    readCell '0' = Just open
    readCell c
      | isDigit c && c > '0' = Just (CellValue (digitToInt c))
      | otherwise = Nothing

getPossibleValues :: Cell -> Candidates
getPossibleValues (PossibleValues v) = v
getPossibleValues _ = IntSet.empty

groupSolved :: Grid -> Group -> Bool
groupSolved grid g = all isCellValue cells && sort (map cellValue cells) == [1 .. length cells]
  where
    cells = map cellInfoCell (cellsOf grid g)

gridSolved :: Board -> Grid -> Bool
gridSolved board grid = all (groupSolved grid) (boardGroups board)
