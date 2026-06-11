module Techniques.HiddenSubsetsTest (tests) where

import ClassicBoard (classicBoard, readClassicGrid)
import Data.Maybe (fromJust)
import qualified Data.IntSet as IntSet
import Grid
import Solver (runSolver)
import Technique
import Techniques.HiddenSubsets
import Techniques.NakedSingles (nakedSingles)
import Techniques.PeerElimination (peerElimination)
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d (lineBoard, testBoard1d)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

cands :: [Value] -> Candidates
cands = IntSet.fromList

applyAll :: Grid -> [Finding] -> Grid
applyAll = foldl (flip applyFinding)

-- A single-group line of nine cells, for exact scenario ports
line9 = lineBoard 9

tests :: TestTree
tests =
  testGroup
    "Techniques.HiddenSubsets"
    [ testCase "Hidden pair shrinks its homes (ported general test)" $ do
        let found = hiddenSubsets 2 testBoard1d generalData
        found
          @?= [ Finding
                  (HiddenSubset 2)
                  [Eliminate 2 (cands [4, 5]), Eliminate 3 (cands [4, 5])]
                  [2, 3]
              ]
        applyAll generalData found @?= generalExpected,
      testCase "Hidden pair via the union rule (ported case B)" $
        hiddenSubsets 2 line9 caseBData
          @?= [ Finding
                  (HiddenSubset 2)
                  [Eliminate 6 (cands [7, 8]), Eliminate 8 (cands [8])]
                  [6, 8]
              ],
      testCase "Staggered hidden triple the old algorithm could not see" $
        hiddenSubsets 3 line9 staggeredData
          @?= [ Finding
                  (HiddenSubset 3)
                  [Eliminate 0 (cands [4, 5]), Eliminate 1 (cands [4, 5]), Eliminate 2 (cands [4, 5])]
                  [0, 1, 2]
              ],
      testCase "Hidden pair on a real classic grid (ported)" $ do
        let start = fromJust $ readClassicGrid ".49132....81479...327685914.96.518...75.28....38.46..5853267...712894563964513..."
            grid = applyAll start (peerElimination classicBoard start)
            found = hiddenSubsets 2 classicBoard grid
        any (\f -> findingInvolved f == [44, 62]) found @? "expected the {1,9} pair at cells 44 and 62"
        let applied = applyAll grid found
        applied !! 44 @?= pv [1, 9]
        applied !! 62 @?= pv [1, 9],
      testCase "Hidden singles place values via the solver (ported updateUniqueValues scenario)" $ do
        let start = [pv [1, 3, 5], pv [1, 3], pv [1, 4], pv [1, 2], pv [1, 5]]
            (_, grid', journal) = runSolver [hiddenSingles, nakedSingles] testBoard1d start
        grid' @?= [pv [1, 3, 5], pv [1, 3], CellValue 4, CellValue 2, pv [1, 5]]
        -- the alias reports itself honestly: a hidden single is HiddenSubset 1
        findingTechnique (head journal) @?= HiddenSubset 1
    ]
  where
    generalData =
      [CellValue 1, pv [4, 5], pv [2, 3, 4, 5], pv [2, 3, 4, 5], pv [4, 5]]
    generalExpected =
      [CellValue 1, pv [4, 5], pv [2, 3], pv [2, 3], pv [4, 5]]
    caseBData =
      [CellValue 3, pv [4, 5, 8], CellValue 1, pv [4, 5, 7], CellValue 2, pv [4, 5], pv [6, 7, 8, 9], pv [7, 8], pv [6, 8, 9]]
    -- 1 lives in cells {0,1}, 2 in {1,2}, 3 in {0,2}: no two value home-sets
    -- match, but their union is three cells -> a valid hidden triple
    staggeredData =
      [pv [1, 3, 4, 5], pv [1, 2, 4, 5], pv [2, 3, 4, 5], pv [4, 5, 6], pv [5, 6, 7], pv [6, 7, 8], pv [7, 8, 9], pv [4, 8, 9], pv [5, 6, 9]]
