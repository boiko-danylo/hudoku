module GridTest (tests) where

import Control.Exception (ErrorCall, evaluate, try)
import qualified Data.IntSet as IntSet
import Grid
import Test.Tasty
import Test.Tasty.HUnit

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

-- Forcing a value that should be a call to `error`: evaluate brings it to
-- WHNF inside IO, try catches the ErrorCall.
isError :: Either ErrorCall a -> Bool
isError (Left _) = True
isError _ = False

tests :: TestTree
tests =
  testGroup
    "Grid display and cell accessors"
    [ testCase "Solved cell shows its value" $
        show (CellValue 5) @?= "5",
      testCase "Candidates cell shows its set" $
        show (pv [1, 2]) @?= "fromList [1,2]",
      testCase "showGrid concatenates cells" $
        showGrid [CellValue 1, CellValue 2, pv [3]] @?= "12fromList [3]",
      testCase "showCellData mirrors show" $ do
        showCellData (CellValue 7) @?= "7"
        showCellData (pv [4, 5]) @?= "fromList [4,5]",
      testCase "cellValue on a candidates cell is an error" $ do
        r <- try (evaluate (cellValue (pv [1])))
        isError r @? "expected an error",
      testCase "cellCandidates on a solved cell is an error" $ do
        r <- try (evaluate (cellCandidates (CellValue 1)))
        isError r @? "expected an error"
    ]
