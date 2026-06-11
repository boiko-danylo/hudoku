module Techniques.NakedSingles (nakedSingles) where

import qualified Data.IntSet as IntSet
import Grid
import Technique

-- | Place any open cell that has exactly one candidate left.
--   The bridge from the candidate world to the value world: the only
--   basic technique that produces Place instead of Eliminate.
nakedSingles :: Technique
nakedSingles _ grid =
  [ Finding NakedSingle [Place i (IntSet.findMin cs)] [i]
    | (i, PossibleValues cs) <- zip [0 ..] grid,
      IntSet.size cs == 1
  ]
