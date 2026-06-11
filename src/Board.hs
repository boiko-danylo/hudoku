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

getUniqueGroupValues :: Board -> Grid -> Group -> Candidates
getUniqueGroupValues (Board d s gs pl) grid groupNum = unique $ freq $ pv groupNum
  where
    unique :: [(Int, Int)] -> Candidates
    unique list = IntSet.fromList $ map fst $ filter (\(x, l) -> l == 1) list
    pv :: Group -> [Int]
    pv = concatMap (pvToList . cellToPV . posToCell')

    pvToList :: Candidates -> [Int]
    pvToList = IntSet.toAscList

    cellToPV :: Cell -> Candidates
    cellToPV (PossibleValues p) = p
    cellToPV _ = IntSet.empty
    posToCell' :: Position -> Cell
    posToCell' = posToCell (Board d s gs pl) grid
    freq :: [Int] -> [(Int, Int)] -- (value, length)
    freq = map (\x -> (head x, length x)) . group . sort

updateUniqueValues :: Board -> Grid -> Grid
updateUniqueValues board grid = updateGridWithValues board grid (updates (z grid))
  where
    updates :: [(Group, Candidates)] -> [(Position, Cell)]
    updates = concatMap updates'
    updates' :: (Group, Candidates) -> [(Position, Cell)]
    updates' (g, vals) = map (\val -> (updatePos g val, CellValue val)) $ IntSet.toAscList vals
    updatePos :: Group -> Int -> Position
    updatePos g v = fromJust $ find (\pos -> isPossibleValuesHasValue (posToCell' pos) v) g
    z :: Grid -> [(Group, Candidates)]
    z grid = zip (boardGroups board) (uniq grid)
    uniq :: Grid -> [Candidates]
    uniq grid = map (getUniqueGroupValues board grid) (boardGroups board)
    posToCell' = posToCell board grid

{-# DEPRECATED updateGridWithValues "Superseded by Technique.applyUpdate (ADR-0006 deltas)" #-}
updateGridWithValues :: Board -> Grid -> [(Position, Cell)] -> Grid
updateGridWithValues board grid values = map update pl
  where
    pl = boardPositionList board
    update :: (Int, Position) -> Cell
    update (index, pos) = fromMaybe (grid !! (index - 1)) (posValue pos)
    posValue :: Position -> Maybe Cell
    posValue pos = snd <$> find (\(p, c) -> p == pos) values -- Only one update per position

updatePossibleValues :: Board -> Grid -> Grid
updatePossibleValues (Board d s gs pl) grid = map updateCell gridToMap
  where
    updateCell :: (Position, Cell) -> Cell
    updateCell (_, CellValue n) = CellValue n
    updateCell (pos, PossibleValues pvals) = PossibleValues (filterPvals pos pvals)
    updateCell (_, EmptyCellVallue) = error "init values before update"

    filterPvals pos = IntSet.filter (\old -> old `IntSet.notMember` getActiveVals (groupsByPos pos))

    gridToMap :: [(Position, Cell)]
    gridToMap = map (\n -> (snd n, grid !! (fst n - 1))) pl
    groupsByPos pos = filter (elem pos) gs

    getActiveVals :: [Group] -> Candidates
    getActiveVals grps = IntSet.fromList $ map (fromJust . getActiveVals'') $ filter filterAval $ getActiveVals' grps
    --  Get array of Cell's
    getActiveVals' :: [Group] -> [Cell]
    getActiveVals' grps = map posToCell' (nub $ concat grps)
    getActiveVals'' (CellValue a) = Just a
    getActiveVals'' _ = Nothing
    filterAval (CellValue _) = True
    filterAval _ = False
    posToCell' = posToCell (Board d s gs pl) grid

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

recursiveUpdateWith :: (Grid -> Grid) -> Grid -> Grid
recursiveUpdateWith f grid
  | grid == update = grid
  | otherwise = recursiveUpdateWith f update
  where
    update :: Grid
    update = f grid

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
