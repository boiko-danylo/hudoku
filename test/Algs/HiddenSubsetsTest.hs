module Algs.HiddenSubsetsTest where

import Algs.HiddenSets
import Board
import ClassicBoard
import Data.IntSet (fromList)
import Grid
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d

tests = testGroup "Hidden subsets tests" [boardTestGroup, generalTest, handleGroupTestGroup, handleSetTestGroup]

boardTestGroup = testGroup "Board tests" [hiddenPairClassic]

hiddenPairClassic = testCase "hiddenPairClassic" $ assertEqual "" expected eval
  where
    grid =
      updatePossibleValues classicBoard $
        readGridWith
          classicInit
          ".49132....81479...327685914.96.518...75.28....38.46..5853267...712894563964513..."
    eval = hiddenSubsetsN classicBoard 2 grid
    expected =
      updateGridWithValues
        classicBoard
        grid
        [ (Position [9, 5], PossibleValues $ fromList [1, 9]),
          (Position [9, 7], PossibleValues $ fromList [1, 9])
        ]

generalData =
  [ CellValue 1,
    PossibleValues $ fromList [4, 5],
    PossibleValues $ fromList [2, 3, 4, 5],
    PossibleValues $ fromList [2, 3, 4, 5],
    PossibleValues $ fromList [4, 5]
  ]

generalExpected =
  [ CellValue 1,
    PossibleValues $ fromList [4, 5],
    PossibleValues $ fromList [2, 3],
    PossibleValues $ fromList [2, 3],
    PossibleValues $ fromList [4, 5]
  ]

generalTest = testCase "general hidden pair test" $ assertEqual "" generalExpected eval
  where
    eval = recursiveUpdateWith solver generalData
    solver = hiddenSubsetsN testBoard1d 2

handleGroupTestGroup = testGroup "handleGroupTestGroup" [handleGroupTestCaseDouble, handleGroupTestCaseDoubleB]

handleGroupTestCaseDouble = testCase "Two subsets groups" $ assertEqual "" expected eval
  where
    eval = handleGroup 2 dataset
    dataset =
      [ (Position [1], 1, CellValue 1),
        (Position [2], 2, PossibleValues $ fromList [4, 5]),
        (Position [3], 3, PossibleValues $ fromList [2, 3, 4, 5]), -- 4,5 remove
        (Position [4], 4, PossibleValues $ fromList [2, 3, 4, 5]), -- 4,5 remove
        (Position [5], 5, PossibleValues $ fromList [4, 5]),
        (Position [6], 6, PossibleValues $ fromList [5, 6]),
        (Position [7], 7, PossibleValues $ fromList [4, 5, 7, 8]), -- 4,5 remove
        (Position [8], 8, PossibleValues $ fromList [4, 5]),
        (Position [9], 9, PossibleValues $ fromList [6, 7, 8, 9]) -- 6,9 remove
      ]
    expected =
      [ (Position [3], 3, PossibleValues $ fromList [2, 3]), -- 4,5 remove
        (Position [4], 4, PossibleValues $ fromList [2, 3]), -- 4,5 remove
        (Position [7], 7, PossibleValues $ fromList [7, 8]), -- 4,5 remove
        (Position [9], 9, PossibleValues $ fromList [7, 8]) -- 6,9 remove
      ]

handleGroupTestCaseDoubleB = testCase "Two subsets groups case B" $ assertEqual "" expected eval
  where
    eval = handleGroup 2 dataset
    dataset =
      [ (Position [1], 1, CellValue 3),
        (Position [2], 2, PossibleValues $ fromList [4, 5, 8]),
        (Position [3], 3, CellValue 1),
        (Position [4], 4, PossibleValues $ fromList [4, 5, 7]),
        (Position [5], 5, CellValue 2),
        (Position [6], 6, PossibleValues $ fromList [4, 5]),
        (Position [7], 7, PossibleValues $ fromList [6, 7, 8, 9]),
        (Position [8], 8, PossibleValues $ fromList [7, 8]),
        (Position [9], 9, PossibleValues $ fromList [6, 8, 9])
      ]
    expected =
      [ (Position [7], 7, PossibleValues $ fromList [6, 9]),
        (Position [9], 9, PossibleValues $ fromList [6, 9])
      ]

handleSetTestGroup = testGroup "handleSetTestGroup" [handleSetTestA]

handleSetTestA = testCase "handleSetTestA" $ assertEqual "" expected eval
  where
    expected = [Position [3], Position [4]]
    eval = handleSet data' $ fromList [2, 3]
    data' =
      [ (Position [1], 1, CellValue 1),
        (Position [2], 2, PossibleValues $ fromList [4, 5]),
        (Position [3], 3, PossibleValues $ fromList [2, 3, 4, 5]),
        (Position [4], 4, PossibleValues $ fromList [2, 3, 4, 5]),
        (Position [5], 5, PossibleValues $ fromList [4, 5])
      ]
