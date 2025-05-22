module Algs.HiddenSets where

import Board
import Control.Applicative
import qualified Data.IntSet as IntSet
import Data.List
import Data.Maybe
import Grid

hiddenSubsetsN :: Board -> Int -> Grid -> Grid
hiddenSubsetsN board size grid = foldl grp grid [0 .. length (boardGroups board) - 1]
  where
    grp curry gn = hiddenSubsetsNGroupN board size gn curry

hiddenSubsetsNGroupN :: Board -> Int -> Int -> Grid -> Grid
hiddenSubsetsNGroupN board n groupNumber grid = applyRestult
  where
    group = boardGroups board !! groupNumber
    cells :: [CellInfo]
    cells = groupToCellInfo board grid group
    handleGroup' = handleGroup n
    results :: [CellInfo]
    results = handleGroup' cells
    applyRestult = updateGridWithValues board grid (map (\ci -> (cellInfoPosition ci, cellInfoCell ci)) results)

handleGroup :: Int -> [CellInfo] -> [CellInfo]
handleGroup n group = sortBy (\a b -> compare (cellInfoIndex a) (cellInfoIndex b)) $ result sets
  where
    av :: [Int] -- All avaliable values in the group
    av = sort . nub $ concatMap (IntSet.toList . getPossibleValues . cellInfoCell) $ filter (isPossibleValues . cellInfoCell) group

    avFreq = map (\x -> (x, avFreq' x)) av -- PV frequency map
    avFreq' x = length $ filter (\ci -> isPossibleValuesHasValue (cellInfoCell ci) x) group

    avFreqN :: Int -> [(Int, Int)] -> [Int] -- Filter frequency map
    avFreqN n list = map fst $ filter (\p -> snd p == n) list

    ss :: [CellPossibleValues] -- PV combinations with length N
    ss = filter ((n ==) . IntSet.size) $ map IntSet.fromList $ subsequences $ avFreqN n avFreq

    -- Found hidden sets
    sets :: [(CellPossibleValues, [Position])]
    sets = mapMaybe sets' ss
      where
        sets' :: CellPossibleValues -> Maybe (CellPossibleValues, [Position])
        sets' pvs = if not $ null hs then Just (pvs, hs) else Nothing
          where
            hs = handleSet group pvs

    -- Transform sets
    result :: [(CellPossibleValues, [Position])] -> [CellInfo]
    result = foldl foldf []

    foldf :: [CellInfo] -> (CellPossibleValues, [Position]) -> [CellInfo]
    foldf c (pvs, pl) = new ++ fc -- Build new + save curry
      where
        ci = getCellInfo group c
        updatePos pos =
          ( -- Build new cellInfo
            pos,
            cellInfoIndex $ ci pos,
            PossibleValues pvs
          )
        new = map updatePos pl -- updated cells
        fc = filter (\(_, i, _) -> i `notElem` map cellInfoIndex new) c -- old cells
    getCellInfo :: [CellInfo] -> [CellInfo] -> Position -> CellInfo
    getCellInfo source res pos = fromMaybe (fromJust $ getCellInfo' pos source) (getCellInfo' pos res)
    getCellInfo' i = find (\ci -> cellInfoPosition ci == i)

handleSet :: [CellInfo] -> CellPossibleValues -> [Position]
handleSet group pvs = if isHiddenSet pv then res pv else []
  where
    n = IntSet.size pvs

    pv :: [(Int, [Position])]
    pv = map pv' $ IntSet.toList pvs
    pv' x = (x, pv'' x)
    pv'' x = map cellInfoPosition $ filter (\ci -> isPossibleValuesHasValue (cellInfoCell ci) x) $ filter (isPossibleValues . cellInfoCell) group

    res :: [(Int, [Position])] -> [Position]
    res [] = []
    res (h : _) = snd h

    isHiddenSet :: [(Int, [Position])] -> Bool
    isHiddenSet set = same && length (snd $ head set) == n
      where
        same = all same' set
        same' :: (Int, [Position]) -> Bool
        same' (_, pl) = pl == snd (head set)
