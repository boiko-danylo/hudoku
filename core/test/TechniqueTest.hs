module TechniqueTest where

import ClassicBoard (readClassicGrid)
import Control.Exception (ErrorCall, evaluate, try)
import Data.Maybe (fromJust)
import qualified Data.IntSet as IntSet
import Grid
import Technique
import Test.Tasty
import Test.Tasty.HUnit

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

cands :: [Value] -> Candidates
cands = IntSet.fromList

tests :: TestTree
tests =
  testGroup
    "Technique"
    [ applyUpdateTests,
      applyFindingTests,
      eliminateToTests,
      eliminateFromTests,
      displayTests
    ]

displayTests :: TestTree
displayTests =
  testGroup
    "debug display and bounds"
    [ testCase "Finding renders for debugging" $
        show (Finding NakedSingle [Place 0 1] [0])
          @?= "Finding {findingTechnique = NakedSingle, findingUpdates = [Place 0 1], findingInvolved = [0]}",
      testCase "CellUpdate and sized TechniqueId render" $ do
        show (Eliminate 2 (cands [4, 7])) @?= "Eliminate 2 (fromList [4,7])"
        show (NakedSubset 2) @?= "NakedSubset 2"
        show (HiddenSubset 1) @?= "HiddenSubset 1",
      testCase "adjustCell out of range is a loud error" $ do
        r <- try (evaluate (adjustCell 5 id [CellValue 1]))
        either (\e -> seq (e :: ErrorCall) True) (const False) r @? "expected an error"
    ]

applyUpdateTests :: TestTree
applyUpdateTests =
  testGroup
    "applyUpdate"
    [ testCase "Eliminate removes candidates from the target cell only" $
        applyUpdate (Eliminate 1 (cands [4, 7])) [pv [1, 2], pv [2, 4, 7, 9], CellValue 5]
          @?= [pv [1, 2], pv [2, 9], CellValue 5],
      testCase "Eliminate on a solved cell is a no-op" $
        applyUpdate (Eliminate 0 (cands [4])) [CellValue 4]
          @?= [CellValue 4],
      testCase "Place turns a candidate cell into a value" $
        applyUpdate (Place 1 6) [pv [1, 2], pv [2, 6]]
          @?= [pv [1, 2], CellValue 6]
    ]

applyFindingTests :: TestTree
applyFindingTests =
  testGroup
    "applyFinding"
    [ testCase "Eliminations on the same cell compose" $
        applyFinding (finding [Eliminate 0 (cands [4, 7]), Eliminate 0 (cands [2])]) snapshot
          @?= [pv [9]],
      testCase "Eliminations on the same cell commute (ADR-0006)" $
        applyFinding (finding [Eliminate 0 (cands [2]), Eliminate 0 (cands [4, 7])]) snapshot
          @?= [pv [9]],
      testCase "Empty finding leaves the grid unchanged" $
        applyFinding (finding []) snapshot
          @?= snapshot,
      -- Port of the old Board.removeCandidates test: eliminate a row's solved
      -- values from the whole row of a classic grid; only candidate cells change.
      testCase "Eliminating across a classic 9x9 row touches only its candidate cells" $
        applyFinding rowFinding classicGrid
          @?= classicExpected
    ]
  where
    snapshot = [pv [2, 4, 7, 9]]
    finding updates = Finding (NakedSubset 2) updates []
    classicGrid = fromJust $ readClassicGrid "...1.5.68......7.19.1....3...7.26...5.......3...87.4...3....8.51.5......79.4.1..."
    rowIndexes = [0 .. 8] -- whole first row, solved cells included
    rowFinding = Finding (NakedSubset 2) [Eliminate i (cands [1, 5, 6, 8]) | i <- rowIndexes] rowIndexes
    candidateIndexes = [0, 1, 2, 4, 6] -- the '.' cells of the first row
    classicExpected =
      [ if i `elem` candidateIndexes then pv [2, 3, 4, 7, 9] else c
        | (i, c) <- zip [0 ..] classicGrid
      ]

eliminateToTests :: TestTree
eliminateToTests =
  testGroup
    "eliminateTo"
    [ testCase "Produces the delta between cell and allowed candidates" $
        eliminateTo 3 (pv [2, 4, 7, 9]) (cands [2, 9])
          @?= Just (Eliminate 3 (cands [4, 7])),
      testCase "Complying cell produces no update" $
        eliminateTo 3 (pv [2, 9]) (cands [1, 2, 9])
          @?= Nothing,
      testCase "Solved cell produces no update" $
        eliminateTo 3 (CellValue 2) (cands [2])
          @?= Nothing
    ]

eliminateFromTests :: TestTree
eliminateFromTests =
  testGroup
    "eliminateFrom"
    [ testCase "Removes only the banned candidates the cell holds" $
        eliminateFrom 3 (pv [2, 4, 7, 9]) (cands [4, 7])
          @?= Just (Eliminate 3 (cands [4, 7])),
      testCase "Cell holding none of the banned produces no update" $
        eliminateFrom 3 (pv [2, 9]) (cands [4, 7])
          @?= Nothing,
      testCase "Solved cell produces no update" $
        eliminateFrom 3 (CellValue 4) (cands [4, 7])
          @?= Nothing
    ]
