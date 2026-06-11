module Techniques.NakedSinglesTest (tests) where

import qualified Data.IntSet as IntSet
import Grid
import Technique
import Techniques.NakedSingles
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d (testBoard1d)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

tests :: TestTree
tests =
  testGroup
    "Techniques.NakedSingles"
    [ testCase "Places every single-candidate cell" $
        nakedSingles testBoard1d [pv [3], CellValue 2, pv [1, 4], EmptyCellVallue, pv [5]]
          @?= [ Finding NakedSingle [Place 0 3] [0],
                Finding NakedSingle [Place 4 5] [4]
              ],
      testCase "No singles, no findings" $
        nakedSingles testBoard1d [pv [1, 2], CellValue 3, pv [4, 5]]
          @?= []
    ]
