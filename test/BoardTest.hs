module BoardTest (tests) where

import Board
import ClassicBoard
import Data.IntSet (empty, fromList, size)
import Grid
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d

tests =
  testGroup
    "Board module tests"
    [ showClassicBoardTest,
      getPossibleValuesTestGroup,
      gridSolvedTests,
      readGridForTests
    ]

showClassicBoardTest = testCase "Classic board structure" $ do
  boardSize classicBoard @?= 9
  boardCellCount classicBoard @?= 81
  length (boardGroups classicBoard) @?= 27
  map (size . groupCells) (boardGroups classicBoard) @?= replicate 27 9

getPossibleValuesTestGroup = testGroup "getPossibleValues test group" [getPossibleValuesTestPv, getPossibleValuesTestValue]

getPossibleValuesTestPv = testCase "Test getPossibleValues on PossibleValues constructor" $ assertEqual "" expected actual
  where
    expected = fromList [1, 3, 9]
    actual = getPossibleValues $ PossibleValues $ fromList [1, 3, 9]

getPossibleValuesTestValue = testCase "Test getPossibleValues on CellValue constructor" $ assertEqual "" empty actual
  where
    actual = getPossibleValues $ CellValue 8

-- Ported from the dropped GameTest (gameSolved scenarios)
gridSolvedTests =
  testGroup
    "gridSolved"
    [ testCase "Check solved simplest grid" $
        gridSolved testBoard1d (map CellValue [1 .. 5]) @?= True,
      testCase "Check not solved simplest grid" $
        gridSolved testBoard1d [CellValue 1, CellValue 2, CellValue 3, CellValue 4, PossibleValues (fromList [5])] @?= False
    ]

readGridForTests =
  testGroup
    "readGridFor"
    [ testCase "Open cells parse to the board's full domain (ported initPossibleValues scenario)" $
        readGridFor testBoard1d "....."
          @?= Just (replicate 5 (PossibleValues (fromList [1 .. 5]))),
      testCase "Values parse, zero counts as open" $
        readGridFor testBoard1d "1.305"
          @?= Just [CellValue 1, open, CellValue 3, open, CellValue 5],
      testCase "Invalid character fails the whole parse" $
        readGridFor testBoard1d "1x..."
          @?= Nothing,
      testCase "Wrong length fails the parse (ADR-0007)" $
        readGridFor testBoard1d "...."
          @?= Nothing
    ]
  where
    open = PossibleValues (fromList [1 .. 5])
