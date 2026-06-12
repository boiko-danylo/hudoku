module SolverTest (tests) where

import ClassicBoard (classicBoard, readClassicGrid)
import Data.Maybe (fromJust)
import qualified Data.IntSet as IntSet
import Grid
import Solver
import Technique
import Test.Tasty
import Test.Tasty.HUnit
import Techniques.NakedSingles (nakedSingles)
import Techniques.NakedSubsets (nakedSubsets)
import TestBoard1d (lineBoard)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

cands :: [Value] -> Candidates
cands = IntSet.fromList

-- Must never be evaluated; proves firstFinding's laziness
bomb :: Technique
bomb _ _ = error "bomb technique was evaluated"

solvedGrid :: Grid
solvedGrid =
  fromJust . readClassicGrid $
    concat
      [ "123456789",
        "456789123",
        "789123456",
        "234567891",
        "567891234",
        "891234567",
        "345678912",
        "678912345",
        "912345678"
      ]

tests :: TestTree
tests =
  testGroup
    "Solver"
    [ firstFindingTests,
      solveTests
    ]

firstFindingTests :: TestTree
firstFindingTests =
  testGroup
    "firstFinding"
    [ testCase "No techniques find nothing" $
        firstFinding [] classicBoard solvedGrid @?= Nothing,
      testCase "Earlier technique wins" $
        firstFinding [always findingA, always findingB] classicBoard solvedGrid
          @?= Just findingA,
      testCase "Later techniques never run when an earlier one finds (laziness)" $
        firstFinding [nakedSingles, bomb] classicBoard oneOpen
          @?= Just (Finding NakedSingle [Place 0 1] [0])
    ]
  where
    oneOpen = pv [1] : drop 1 solvedGrid
    always f _ _ = [f]
    findingA = Finding NakedSingle [Place 10 1] [10]
    findingB = Finding NakedSingle [Place 20 2] [20]

solveTests :: TestTree
solveTests =
  testGroup
    "runSolver"
    [ testCase "Outcome renders for journal display" $ do
        show Solved @?= "Solved"
        show Stuck @?= "Stuck",
      testCase "Solved grid with no findings reports Solved, empty journal" $
        runSolverWith [] classicBoard solvedGrid
          @?= (Solved, solvedGrid, []),
      testCase "Unsolvable-by-these-techniques grid reports Stuck" $ do
        let (outcome, grid', journal) = runSolverWith [nakedSubsets 2] (lineBoard 9) size2Grid
        outcome @?= Stuck
        grid' @?= size2Expected
        journal
          @?= [ Finding
                  (NakedSubset 2)
                  [Eliminate 2 (cands [2, 3]), Eliminate 5 (cands [3])]
                  [6, 8]
              ],
      testCase "Applies one finding per scan and journals them in order" $ do
        let twoOpen = pv [1] : pv [2] : drop 2 solvedGrid
            (outcome, grid', journal) = runSolverWith [nakedSingles] classicBoard twoOpen
        outcome @?= Solved
        grid' @?= solvedGrid
        journal
          @?= [ Finding NakedSingle [Place 0 1] [0],
                Finding NakedSingle [Place 1 2] [1]
              ]
    ]
  where
    size2Grid =
      [CellValue 7, CellValue 6, pv [2, 3, 4, 8], CellValue 9, CellValue 1, pv [3, 4, 8], pv [2, 3], CellValue 5, pv [2, 3]]
    size2Expected =
      [CellValue 7, CellValue 6, pv [4, 8], CellValue 9, CellValue 1, pv [4, 8], pv [2, 3], CellValue 5, pv [2, 3]]
