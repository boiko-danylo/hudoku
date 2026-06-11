module Board where

import Data.Char (digitToInt, isDigit)
import Data.IntSet (IntSet)
import qualified Data.IntSet as IntSet
import Data.Ix (Ix (range))
import Data.List
import Data.Maybe
import Data.Tuple.Extra
import Grid

-- We can process N-dimensional sudoku.
-- data Position = Position [Int] deriving (Show, Eq);

newtype Position = Position [Int]
  deriving (Show, Eq)

type Dimensions = Int

type Size = Int

type GridIndex = Int

type GroupIndex = Int

type PositionList = [(GridIndex, Position)]

type Group = [Position]

type CellInfo = (Position, GridIndex, Cell)

data Board = Board Dimensions Size [Group] PositionList

instance Show Board where
  show (Board d s g _) = "Dim: " ++ show d ++ ", Size: " ++ show s ++ ", Groups: " ++ show (length g)

boardValues :: Board -> Candidates
boardValues (Board _ n _ _) = IntSet.fromList $ range (1, n)

-- | Parse a grid for this board: '.' and '0' are open cells carrying the
--   board's full domain as candidates (ADR-0004: construction needs the
--   board, because only the board knows what "all candidates" means).
readGridFor :: Board -> String -> Maybe Grid
readGridFor board = traverse readCell
  where
    open = PossibleValues (boardValues board)
    readCell '.' = Just open
    readCell '0' = Just open
    readCell c
      | isDigit c && c > '0' = Just (CellValue (digitToInt c))
      | otherwise = Nothing

showBoardGroups :: Board -> String
showBoardGroups (Board _ _ g _) = showGroups g

getPossibleValues :: Cell -> Candidates
getPossibleValues (PossibleValues v) = v
getPossibleValues _ = IntSet.empty

showGroups :: [Group] -> String
showGroups [] = ""
showGroups g = show (head g) ++ "\n" ++ showGroups (tail g)

posToCell :: Board -> Grid -> Position -> Cell
posToCell b g p = g !! posToNum b p

posToNum :: Board -> Position -> GridIndex
posToNum (Board _ _ _ pl) = pos
  where
    pos x = fst (fromJust $ pos' x) - 1
    pos' x = find (\(_, pos) -> pos == x) pl

posToCellInfo :: Board -> Grid -> Position -> CellInfo
posToCellInfo b g p = (p, posToNum b p, posToCell b g p)

groupToCellInfo :: Board -> Grid -> Group -> [CellInfo]
groupToCellInfo b g = map $ posToCellInfo b g

cellInfoIndex :: CellInfo -> GridIndex
cellInfoIndex = snd3

cellInfoCell :: CellInfo -> Cell
cellInfoCell = thd3

boardGroups :: Board -> [Group]
boardGroups (Board _ _ g _) = g

boardSize :: Board -> [Size]
boardSize (Board d s g pl) = map dimSize [1 .. d]
  where
    dimSize d = maximum $ dimSize' d
    dimSize' d = map (\(_, Position pos) -> pos !! (d - 1)) pl

boardGridLength :: Board -> Int
boardGridLength (Board _ _ _ pl) = length pl

boardPositionList :: Board -> PositionList
boardPositionList (Board _ _ _ pl) = pl

groupSolved :: Board -> Group -> Grid -> Bool
groupSolved board group grid = not (hasNothing group || notEqual group)
  where
    hasNothing = any (isNothing . cellToValue . posToCell')
    notEqual g = targetValues /= sort (map (fromJust . cellToValue . posToCell') g)
    posToCell' = posToCell board grid
    cellToValue (CellValue a) = Just a
    cellToValue _ = Nothing
    targetValues = [1 .. (length group)]

gridSolved :: Board -> Grid -> Bool
gridSolved (Board d s gs pl) grid = all (\g -> groupSolved (Board d s gs pl) g grid) gs

