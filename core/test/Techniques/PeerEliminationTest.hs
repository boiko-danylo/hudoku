module Techniques.PeerEliminationTest (tests) where

import qualified Data.IntSet as IntSet
import Grid
import Technique
import Techniques.PeerElimination
import Test.Tasty
import Test.Tasty.HUnit
import TestBoard1d (testBoard1d)

pv :: [Value] -> Cell
pv = PossibleValues . IntSet.fromList

cands :: [Value] -> Candidates
cands = IntSet.fromList

tests :: TestTree
tests =
  testGroup
    "Techniques.PeerElimination"
    [ testCase "Bans solved group values from the group's open cells" $
        peerElimination testBoard1d [CellValue 1, pv [1, 2], pv [1, 2, 3], CellValue 4, pv [4, 5]]
          @?= [ Finding
                  PeerElimination
                  [Eliminate 1 (cands [1]), Eliminate 2 (cands [1]), Eliminate 4 (cands [4])]
                  [0, 3]
              ],
      testCase "Group with no solved cells yields nothing" $
        peerElimination testBoard1d (replicate 5 (pv [1, 2, 3, 4, 5]))
          @?= [],
      testCase "Fully solved group yields nothing" $
        peerElimination testBoard1d (map CellValue [1 .. 5])
          @?= [],
      testCase "Open cells already free of solved values yield nothing" $
        peerElimination testBoard1d [CellValue 1, pv [2, 3], pv [2, 3], pv [4, 5], pv [4, 5]]
          @?= []
    ]
