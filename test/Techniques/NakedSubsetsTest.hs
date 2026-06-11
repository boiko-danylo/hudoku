module Techniques.NakedSubsetsTest (tests) where

import Board (CellInfo, GridIndex, Position (..), boardGridLength, boardValues)
import ClassicBoard (classicBoard)
import qualified Data.IntSet as IntSet
import Grid
import Technique
import Techniques.NakedSubsets
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d (lineBoard)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

cands :: [Value] -> Candidates
cands = IntSet.fromList

-- A CellInfo whose position doesn't matter (piecewise tests never look at it)
ci :: GridIndex -> Cell -> CellInfo
ci i c = (Position [i], i, c)

-- Pad a row prefix out to a full classic grid with open cells
classicGridOf :: [Cell] -> Grid
classicGridOf cells = take len (cells ++ replicate len openCell)
  where
    len = boardGridLength classicBoard

openCell :: Cell
openCell = PossibleValues (boardValues classicBoard)

-- A nine-cell single-group board: scenarios stated on one group stay exact
line9 = lineBoard 9

applyAll :: Grid -> [Finding] -> Grid
applyAll = foldl (flip applyFinding)

tests :: TestTree
tests =
  testGroup
    "Techniques.NakedSubsets"
    [ valueSetsTests,
      nakedSubsetAtTests,
      nakedSubsetsTests,
      portedScenarioTests
    ]

-- Piecewise: valueSets

valueSetsTests :: TestTree
valueSetsTests =
  testGroup
    "valueSets"
    [ testCase "All size-2 sets from the open cells' candidate union" $
        valueSets 2 [ci 0 (pv [4, 7]), ci 1 (pv [4, 7]), ci 2 (pv [2, 4, 9])]
          @?= [cands [2, 4], cands [2, 7], cands [4, 7], cands [2, 9], cands [4, 9], cands [7, 9]],
      testCase "No open cells produce no sets" $
        valueSets 2 [] @?= []
    ]

-- Piecewise: nakedSubsetAt

nakedSubsetAtTests :: TestTree
nakedSubsetAtTests =
  testGroup
    "nakedSubsetAt"
    [ testCase "Naked pair eliminates from non-members, members are involved" $
        nakedSubsetAt 2 pairCells (cands [4, 7])
          @?= Just (Finding (NakedSubset 2) [Eliminate 2 (cands [4])] [0, 1]),
      testCase "Set with too few member cells is not naked" $
        nakedSubsetAt 2 pairCells (cands [2, 4])
          @?= Nothing,
      testCase "Naked set eliminating nothing is no finding" $
        nakedSubsetAt 2 [ci 0 (pv [4, 7]), ci 1 (pv [4, 7])] (cands [4, 7])
          @?= Nothing
    ]
  where
    pairCells = [ci 0 (pv [4, 7]), ci 1 (pv [4, 7]), ci 2 (pv [2, 4, 9])]

-- Whole technique on a classic board

nakedSubsetsTests :: TestTree
nakedSubsetsTests =
  testGroup
    "nakedSubsets"
    [ testCase "Triple formed by strict subsets of its value-set" $
        nakedSubsets 3 line9 tripleGrid
          @?= [ Finding
                  (NakedSubset 3)
                  [Eliminate 3 (cands [1]), Eliminate 4 (cands [2, 3])]
                  [0, 1, 2]
              ],
      testCase "Pair whose elimination changes nothing yields no findings" $
        nakedSubsets 2 line9 noEffectGrid
          @?= [],
      testCase "Same pair found independently in row and box" $ do
        let found = nakedSubsets 2 classicBoard twoGroupsGrid
        length found @?= 2
        let applied = applyAll twoGroupsGrid found
        applied !! 2 @?= pv [2, 9]
        applied !! 9 @?= pv [9]
    ]
  where
    tripleGrid =
        [pv [1, 2], pv [2, 3], pv [1, 3], pv [1, 4, 5], pv [2, 3, 9], CellValue 6, CellValue 7, CellValue 8, pv [4, 5, 9]]
    noEffectGrid =
        [pv [4, 7], pv [4, 7], CellValue 1, CellValue 2, CellValue 3, CellValue 5, CellValue 6, CellValue 8, CellValue 9]
    twoGroupsGrid =
      classicGridOf
        ([pv [4, 7], pv [4, 7], pv [2, 4, 9]] ++ replicate 6 openCell ++ [pv [4, 7, 9]])

-- Ports of the Algs.NakedSubsetsMonadicTest scenarios (coverage preserved)

portedScenarioTests :: TestTree
portedScenarioTests =
  testGroup
    "ported old scenarios"
    [ testCase "Size-2 row scenario produces the old result" $ do
        let found = nakedSubsets 2 line9 size2Grid
        found
          @?= [ Finding
                  (NakedSubset 2)
                  [Eliminate 2 (cands [2, 3]), Eliminate 5 (cands [3])]
                  [6, 8]
              ]
        applyAll size2Grid found @?= size2Expected,
      testCase "Size-3 row scenario produces the old result" $ do
        let found = nakedSubsets 3 line9 size3Grid
        length found @?= 1
        applyAll size3Grid found @?= size3Expected,
      testCase "Size-4 row scenario produces the old result" $ do
        let found = nakedSubsets 4 line9 size4Grid
        length found @?= 1
        applyAll size4Grid found @?= size4Expected,
      testCase "Two pairs in one row compose on a shared cell" $ do
        let found = nakedSubsets 2 line9 twoPairsGrid
        length found @?= 2
        applyAll twoPairsGrid found !! 2 @?= pv [8]
    ]
  where
    size2Grid =
        [CellValue 7, CellValue 6, pv [2, 3, 4, 8], CellValue 9, CellValue 1, pv [3, 4, 8], pv [2, 3], CellValue 5, pv [2, 3]]
    size2Expected =
        [CellValue 7, CellValue 6, pv [4, 8], CellValue 9, CellValue 1, pv [4, 8], pv [2, 3], CellValue 5, pv [2, 3]]
    size3Grid =
        [pv [7, 8, 9], CellValue 1, pv [7, 8], pv [3, 5, 9], CellValue 4, pv [5, 6, 8, 9], pv [7, 9], CellValue 2, pv [3, 5, 6, 7, 8, 9]]
    size3Expected =
        [pv [7, 8, 9], CellValue 1, pv [7, 8], pv [3, 5], CellValue 4, pv [5, 6], pv [7, 9], CellValue 2, pv [3, 5, 6]]
    size4Grid =
        [CellValue 1, pv [4, 5, 6], pv [4, 9], pv [3, 5, 6], pv [3, 5, 6, 7], pv [3, 5, 7], pv [2, 4, 8, 9], pv [2, 4], pv [2, 8, 9]]
    size4Expected =
        [CellValue 1, pv [5, 6], pv [4, 9], pv [3, 5, 6], pv [3, 5, 6, 7], pv [3, 5, 7], pv [2, 4, 8, 9], pv [2, 4], pv [2, 8, 9]]
    twoPairsGrid =
        [CellValue 7, CellValue 6, pv [2, 3, 4, 8], pv [4, 5], CellValue 1, pv [4, 5], pv [2, 3], CellValue 5, pv [2, 3]]
