module Algs.NakedSubsetsMonadic where

import Algs.Algs (Algorithm (NackedSet))
import Board
import Control.Applicative
import Data.Aeson (Value (Bool))
import Data.Aeson.KeyMap (size)
import Data.IntSet (IntSet, fromList, size, toList)
import Data.List
import Data.Maybe
import Data.Set (Set)
import Game
import Grid
import Steps (Step (Step), Steps)

-- |
--  This is generic algorithm for naked pairs, triples, etc.
--
--  The idea is:
--  1. get all the board groups and update grid after each group handling.
--  2. For each group we're running same generalized algorighm parametrized with N (2 for pairs).
--  3. Algorithm look for set of N cells that conatin only n<=N same candidates.
--  4. Then we can remove all N candidates from rest of grouop.
--
--  5. Monadic means it return a list of updates
type SubsetSize = Int

type Subset = IntSet

showSubset :: Subset -> String
showSubset ss = "(" ++ intercalate "," (map show $ Data.IntSet.toList ss) ++ ")"

findNakedSubsetsNSteps :: SubsetSize -> Game Steps
findNakedSubsetsNSteps size = do
  board <- getBoard
  let groupIndexList = boardGroupIndexes board

  -- res <- fmap $ findNakedSubsetsNGroupN size groupIndexList
  return []

subsetToStep :: Subset -> GroupIndex -> Game Step
subsetToStep s i = do
  board <- getBoard
  grid <- getGrid
  let ci = getCellsInfoFromGroup board grid i
  let proccessed = fmap applySS ci

  return $ Step NackedSet "Values " (changedCells ci)
  where
    applySS :: CellInfo -> (Bool, CellInfo)
    applySS ci = (checkSubsetPV s (cellInfoCell ci), setCellInfoValue ci (applySubset s (cellInfoCell ci)))
    changedCells :: [CellInfo] -> [CellInfo]
    changedCells ci = map snd $ filter fst $ map applySS ci

    desc :: [CellInfo] -> String
    desc res = "Values " ++ showSubset s ++ " can be removed from cells "

applyNakedSubsetsN :: SubsetSize -> Game ()
applyNakedSubsetsN size = do
  grid <- getGrid
  let updated = findNakedSubsetsNCells size grid
  fillGrid updated

findNakedSubsetsNGroupN :: SubsetSize -> GroupIndex -> Game [Subset]
findNakedSubsetsNGroupN size groupIndex = do
  board <- getBoard
  grid <- getGrid
  let group = boardGroups board !! groupIndex
      cellInfoList = groupToCellInfo board grid group
      cellList = fmap cellInfoCell cellInfoList
      foundSubsets = findNakedSubsetsNSubsets size cellList
  return foundSubsets

findNakedSubsetsNCells :: SubsetSize -> [Cell] -> [Cell]
findNakedSubsetsNCells size input = fmap (applySubsets subsets) input
  where
    subsets = findNakedSubsetsNSubsets size input

findNakedSubsetsNSubsets :: SubsetSize -> [Cell] -> [Subset]
findNakedSubsetsNSubsets size input = result
  where
    possibleSubsets :: [Subset]
    possibleSubsets = filter (\l -> Data.IntSet.size l <= size) $ map Data.IntSet.fromList $ subsequences possibleSubsets'

    possibleSubsets' :: [Int]
    possibleSubsets' = dedup $ concatMap (Data.IntSet.toList . getPossibleValues) input

    dedup = map head . group . sort

    checkSubset :: Subset -> Bool
    checkSubset subset = checkSubsetCount subset == size

    checkSubsetCount :: Subset -> Int
    checkSubsetCount subset = length $ filter id $ checkSubsetPVCells subset

    checkSubsetPVCells :: Subset -> [Bool]
    checkSubsetPVCells subset = fmap (checkSubsetPV subset) input

    subsets = filter checkSubset possibleSubsets
    result = subsets

{-# DEPRECATED applySubset, applySubsets "Superseded by Technique.applyUpdate (ADR-0006 deltas)" #-}
applySubset :: Subset -> Cell -> Cell
applySubset subset cell =
  if checkSubsetPV subset cell then cell else removeCellCandidates cell subset

checkSubsetPV :: Subset -> Cell -> Bool
checkSubsetPV subset (PossibleValues pv) = null $ Data.IntSet.toList pv \\ Data.IntSet.toList subset
checkSubsetPV subset _ = False

applySubsets :: [Subset] -> Cell -> Cell
applySubsets subsets cell = foldl (flip applySubset) cell subsets
