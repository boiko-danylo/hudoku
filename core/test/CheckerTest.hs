module CheckerTest (tests) where

import Checker
import qualified Data.IntSet as IntSet
import Grid
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d (testBoard1d)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

tests :: TestTree
tests =
  testGroup
    "Checker"
    [ testCase "Fully solved valid group is correct" $
        isBoardCorrect testBoard1d (map CellValue [1 .. 5]) @?= True,
      testCase "Duplicate solved value in a group is incorrect" $
        isBoardCorrect testBoard1d [CellValue 1, CellValue 1, CellValue 3, CellValue 4, CellValue 5] @?= False,
      testCase "Open cells do not affect correctness" $
        isBoardCorrect testBoard1d [CellValue 1, pv [1, 2], pv [2, 3], CellValue 4, pv [5]] @?= True,
      testCase "Fully open grid is trivially correct" $
        isBoardCorrect testBoard1d (replicate 5 (pv [1 .. 5])) @?= True
    ]
