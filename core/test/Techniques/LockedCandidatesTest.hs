module Techniques.LockedCandidatesTest (tests) where

import Board
import qualified Data.IntSet as IntSet
import Grid
import Technique
import Techniques.LockedCandidates
import Test.Tasty
import Test.Tasty.HUnit

-- The geometry-freeness proof: no rows, no boxes, no 9x9 anywhere.
-- Five cells, domain {1,2,3}; A = {0,1,2} declares Permutation (every
-- value must appear in it), B = {1,2,3,4} is merely all-different.
-- A ∩ B = {1,2}.
tinyBoard :: Board
tinyBoard =
  Board
    { boardSize = 3,
      boardCellCount = 5,
      boardGroups =
        [ Group Permutation (IntSet.fromList [0, 1, 2]),
          Group AllDifferent (IntSet.fromList [1, 2, 3, 4])
        ]
    }

open :: [Value] -> Cell
open = PossibleValues . IntSet.fromList

tests :: TestTree
tests =
  testGroup
    "Techniques.LockedCandidates"
    [ testCase "value locked into the overlap is banned from the rest of B" $ do
        -- 1 is impossible in cell 0, so its homes in A are {1,2} ⊆ A∩B:
        -- 1 must land there, hence cells 3 and 4 cannot hold it.
        let grid = [open [2, 3], open [1, 2, 3], open [1, 2, 3], open [1, 2, 3], open [1, 2, 3]]
            findings = lockedCandidates tinyBoard grid
        map findingUpdates findings
          @?= [ [ Eliminate 3 (IntSet.singleton 1),
                  Eliminate 4 (IntSet.singleton 1)
                ]
              ],
      testCase "B never proves: it is not Permutation-strong" $ do
        -- mirror setup: 1 confined to {1,2} from B's side (impossible in
        -- 3 and 4). B only declares AllDifferent, so nothing forces 1 to
        -- appear in B at all - no inference, no findings.
        let grid = [open [1, 2, 3], open [1, 2, 3], open [1, 2, 3], open [2, 3], open [2, 3]]
        lockedCandidates tinyBoard grid @?= [],
      testCase "untouched grid has no locked candidates" $ do
        let grid = replicate 5 (open [1, 2, 3])
        lockedCandidates tinyBoard grid @?= []
    ]
