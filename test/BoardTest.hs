module BoardTest (tests) where

import Board
import ClassicBoard
import Data.IntSet (empty, fromList)
import Grid
import Test.Tasty
import Test.Tasty.HUnit

tests =
  testGroup
    "Board module tests"
    [ showClassicBoardTest,
      getPossibleValuesTestGroup
    ]

showClassicBoardTest = testCase "Show classic board test" $ assertEqual "" expected actual
  where
    expected = "Dim: 2, Size: 9, Groups: 27"
    actual = show classicBoard

getPossibleValuesTestGroup = testGroup "getPossibleValues test group" [getPossibleValuesTestPv, getPossibleValuesTestEmpty, getPossibleValuesTestValue]

getPossibleValuesTestPv = testCase "Test getPossibleValues on PossibleValues constructor" $ assertEqual "" expected actual
  where
    expected = fromList [1, 3, 9]
    actual = getPossibleValues $ PossibleValues $ fromList [1, 3, 9]

getPossibleValuesTestEmpty = testCase "Test getPossibleValues on Empty constructor" $ assertEqual "" empty actual
  where
    actual = getPossibleValues EmptyCellVallue

getPossibleValuesTestValue = testCase "Test getPossibleValues on CellValue constructor" $ assertEqual "" empty actual
  where
    actual = getPossibleValues $ CellValue 8
