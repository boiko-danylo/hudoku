module GridShowersTest (tests) where

import Board (boardCellCount)
import ClassicBoard (classicVariant, readClassicGrid)
import Data.Maybe (fromJust)
import GridShowers
import Test.Tasty
import Test.Tasty.HUnit
import Variant

tests :: TestTree
tests =
  testGroup
    "GridShowers and Variant"
    [ testCase "Golden render of a solved classic grid" $
        showGridPV classicVariant solvedGrid @?= unlines solvedRows,
      testCase "classicVariant bundles the classic board and a 9x9 layout" $ do
        boardCellCount (variantBoard classicVariant) @?= 81
        layoutWidth (variantLayout classicVariant) @?= 9
        layoutHeight (variantLayout classicVariant) @?= 9
    ]
  where
    solvedRows =
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
    solvedGrid = fromJust (readClassicGrid (concat solvedRows))
