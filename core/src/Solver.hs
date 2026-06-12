module Solver where

import Board
import Control.Monad.RWS.CPS
import Data.Maybe (listToMaybe)
import Grid
import Technique
import Techniques.HiddenSubsets
import Techniques.LockedCandidates
import Techniques.NakedSingles
import Techniques.NakedSubsets
import Techniques.PeerElimination

-- A Step is an applied Finding (DESIGN.md terminology)
type Step = Finding

data Outcome = Solved | Stuck
  deriving (Show, Eq)

type Solve a = RWS Board [Step] Grid a

-- | Apply-and-rescan: run techniques in the given order, apply the first
--   finding, log it, start over. Ends when no technique finds anything.
solveWith :: [Technique] -> Solve Outcome
solveWith techniques = do
  board <- ask
  grid <- get
  case firstFinding techniques board grid of
    Nothing -> pure (if gridSolved board grid then Solved else Stuck)
    Just finding -> do
      put (applyFinding finding grid)
      tell [finding]
      solveWith techniques

-- | The first finding any technique produces, techniques tried in order.
--   Lazy: techniques after the first producing one never run.
firstFinding :: [Technique] -> Board -> Grid -> Maybe Finding
firstFinding ts board grid = listToMaybe (concatMap (\t -> t board grid) ts)

-- | The engine-level runner: run exactly these techniques.
runSolverWith :: [Technique] -> Board -> Grid -> (Outcome, Grid, [Step])
runSolverWith techniques = runRWS (solveWith techniques)

-- | The catalog-level runner: select what fits the board, then run.
runSolver :: [TechniqueDef] -> Board -> Grid -> (Outcome, Grid, [Step])
runSolver defs board = runSolverWith (map techRun (applicable board defs)) board

-- | Which techniques fit this board: every premise must be met by some
--   group (ADR-0010). Advertisement only — soundness lives in the
--   techniques themselves, which select qualifying groups per group.
applicable :: Board -> [TechniqueDef] -> [TechniqueDef]
applicable board = filter (all supported . techNeeds)
  where
    supported need = any ((`implies` need) . groupConstraint) (boardGroups board)

-- | The default arsenal, cheapest first; the order is the difficulty scale.
standardTechniques :: [TechniqueDef]
standardTechniques =
  [ TechniqueDef PeerElimination [AllDifferent] peerElimination,
    TechniqueDef NakedSingle [] nakedSingles,
    TechniqueDef (HiddenSubset 1) [Permutation] hiddenSingles,
    TechniqueDef LockedCandidates [Permutation] lockedCandidates,
    TechniqueDef (NakedSubset 2) [AllDifferent] (nakedSubsets 2),
    TechniqueDef (HiddenSubset 2) [Permutation] (hiddenSubsets 2),
    TechniqueDef (NakedSubset 3) [AllDifferent] (nakedSubsets 3),
    TechniqueDef (HiddenSubset 3) [Permutation] (hiddenSubsets 3),
    TechniqueDef (NakedSubset 4) [AllDifferent] (nakedSubsets 4),
    TechniqueDef (HiddenSubset 4) [Permutation] (hiddenSubsets 4)
  ]
