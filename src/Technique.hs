module Technique where

import Board (Board, GridIndex)
import qualified Data.IntSet as IntSet
import Data.List (foldl')
import Grid

-- Which technique produced a finding
data TechniqueId = NakedSubset | HiddenSubset
  deriving (Read, Show, Enum, Eq)

-- An instruction against the *current* grid (ADR-0006)
data CellUpdate
  = Eliminate GridIndex Candidates -- remove these candidates from this cell
  | Place GridIndex Value -- this cell becomes this value
  deriving (Show, Eq)

-- A technique's conclusion: pure data, no strings, no grid (ADR-0001)
data Finding = Finding
  { findingTechnique :: TechniqueId,
    findingUpdates :: [CellUpdate],
    findingInvolved :: [GridIndex] -- witness cells, for UI/explanations
  }
  deriving (Show, Eq)

type Technique = Board -> Grid -> [Finding]

-- Size of a naked/hidden subset (2 = pair, 3 = triple, ...)
type SubsetSize = Int

-- Apply side: the generic machinery (ADR-0001)

applyUpdate :: CellUpdate -> Grid -> Grid
applyUpdate (Eliminate i cs) = adjustCell i (`removeCellCandidates` cs)
applyUpdate (Place i v) = adjustCell i (const (CellValue v))

applyFinding :: Finding -> Grid -> Grid
applyFinding f grid = foldl' (flip applyUpdate) grid (findingUpdates f)

-- Replace the cell at an index by transforming it
adjustCell :: GridIndex -> (Cell -> Cell) -> Grid -> Grid
adjustCell i f grid = case splitAt i grid of
  (before, c : after) -> before ++ f c : after
  (_, []) -> error ("adjustCell: index out of range: " ++ show i)

-- Find side: diff helper for techniques

-- | The elimination that shrinks a cell's candidates to `allowed`.
--   Nothing when the cell already complies, so no-op findings never exist.
eliminateTo :: GridIndex -> Cell -> Candidates -> Maybe CellUpdate
eliminateTo i (PossibleValues cs) allowed
  | IntSet.null removed = Nothing
  | otherwise = Just (Eliminate i removed)
  where
    removed = cs `IntSet.difference` allowed
eliminateTo _ _ _ = Nothing

-- | The dual of eliminateTo: remove `banned` candidates from a cell.
--   Nothing when the cell holds none of them, so no-op findings never exist.
eliminateFrom :: GridIndex -> Cell -> Candidates -> Maybe CellUpdate
eliminateFrom i (PossibleValues cs) banned
  | IntSet.null removed = Nothing
  | otherwise = Just (Eliminate i removed)
  where
    removed = cs `IntSet.intersection` banned
eliminateFrom _ _ _ = Nothing
