module Grid where

import Data.IntSet (IntSet, difference, member)
import Prelude

-- Semantic types (ADR-0005)
type Value = Int

type Candidates = IntSet

-- Two-state by design (ADR-0004): a cell is solved or it has candidates.
-- "Empty" is just PossibleValues over the board's full domain.
data Cell = CellValue Int | PossibleValues Candidates deriving (Eq)

instance Show Cell where
  show (CellValue a) = show a
  show (PossibleValues x) = show x

isCellValue (CellValue _) = True
isCellValue _ = False

cellValue :: Cell -> Int
cellValue (CellValue n) = n
cellValue _ = error "Cell is not value"

isPossibleValues (PossibleValues _) = True
isPossibleValues _ = False

cellCandidates :: Cell -> Candidates
cellCandidates (PossibleValues x) = x
cellCandidates _ = error "Cell can't have candidates"

isPossibleValuesHasValue :: Cell -> Int -> Bool
isPossibleValuesHasValue (PossibleValues vals) x = x `member` vals
isPossibleValuesHasValue _ _ = False

type Grid = [Cell]

{- TODO: Rework, print as table-}
showGrid :: Grid -> String
showGrid = concatMap show

showCellData :: Cell -> String
showCellData (CellValue n) = show n
showCellData (PossibleValues p) = show p

removeCellCandidates :: Cell -> Candidates -> Cell
removeCellCandidates (PossibleValues p) list = PossibleValues (difference p list)
removeCellCandidates x _ = x
