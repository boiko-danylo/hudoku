module Board where

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

type GridIndex = Int

type GroupIndex = Int

type PositionList = [(GridIndex, Position)]

type Group = [Position]

type CellInfo = (Position, GridIndex, Cell)

-- Dim, size, groups
data Board = Board Int Int [Group] PositionList

instance Show Board where
  show (Board d s g _) = "Dim: " ++ show d ++ ", Size: " ++ show s ++ ", Groups: " ++ show (length g)

boardValues :: Board -> Candidates
boardValues (Board _ n _ _) = IntSet.fromList $ range (1, n)

showBoardGroups :: Board -> String
showBoardGroups (Board _ _ g _) = showGroups g

getPossibleValues :: Cell -> Candidates
getPossibleValues (PossibleValues v) = v
getPossibleValues _ = IntSet.empty

showGroups :: [Group] -> String
showGroups [] = ""
showGroups g = show (head g) ++ "\n" ++ showGroups (tail g)

boardGroupIndexes :: Board -> [GroupIndex]
boardGroupIndexes b = [0 .. length (boardGroups b) - 1]

cellGetGroups :: Board -> Position -> [Group]
cellGetGroups (Board _ _ gs _) p = filter (elem p) gs

posToCell :: Board -> Grid -> Position -> Cell
posToCell b g p = g !! posToNum b p

posToNum :: Board -> Position -> Int
posToNum (Board _ _ _ pl) = pos
  where
    pos x = fst (fromJust $ pos' x) - 1
    pos' x = find (\(_, pos) -> pos == x) pl

posToCellInfo :: Board -> Grid -> Position -> CellInfo
posToCellInfo b g p = (p, posToNum b p, posToCell b g p)

groupToCellInfo :: Board -> Grid -> Group -> [CellInfo]
groupToCellInfo b g = map $ posToCellInfo b g

cellInfoPosition :: CellInfo -> Position
cellInfoPosition = fst3

cellInfoIndex :: CellInfo -> Int
cellInfoIndex = snd3

cellInfoCell :: CellInfo -> Cell
cellInfoCell = thd3

setCellInfoValue :: CellInfo -> Cell -> CellInfo
setCellInfoValue (p, i, _) n = (p, i, n)

numToPos :: Board -> Grid -> Int -> Position
numToPos (Board _ _ _ pl) g p = snd (fromJust $ find (\(i, _) -> i == p) pl)

boardGroups :: Board -> [Group]
boardGroups (Board _ _ g _) = g

boardSize :: Board -> [Int]
boardSize (Board d s g pl) = map dimSize [1 .. d]
  where
    dimSize d = maximum $ dimSize' d
    dimSize' d = map (\(_, Position pos) -> pos !! (d - 1)) pl

boardGridLength :: Board -> Int
boardGridLength (Board _ _ _ pl) = length pl

boardDimensions :: Board -> Int
boardDimensions (Board d _ _ _) = d

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

getCellsInfoFromGroup :: Board -> Grid -> Int -> [CellInfo]
getCellsInfoFromGroup board grid group = map posToCellInfo' boardGroup
  where
    boardGroup = boardGroups board !! group
    posToCellInfo' = posToCellInfo board grid

getCellsFromGroup :: Board -> Grid -> Int -> [Cell]
getCellsFromGroup board grid group = map posToCell' boardGroup
  where
    boardGroup = boardGroups board !! group
    posToCell' = posToCell board grid

-- TODO: Deprecate
initPossibleValues' board = map initCell
  where
    initCell EmptyCellVallue = PossibleValues $ boardValues board
    initCell a = a
