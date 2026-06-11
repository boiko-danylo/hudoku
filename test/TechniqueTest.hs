module TechniqueTest where

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
      eliminateToTests
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
          @?= snapshot
    ]
  where
    snapshot = [pv [2, 4, 7, 9]]
    finding updates = Finding NakedSubset updates []

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
