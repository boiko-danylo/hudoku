module Solver where

import Board
import Control.Monad.RWS.CPS
import Data.Maybe (listToMaybe)
import Grid
import Technique

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

-- | Unwrap the machine: final verdict, final grid, the journal.
runSolver :: [Technique] -> Board -> Grid -> (Outcome, Grid, [Step])
runSolver techniques = runRWS (solveWith techniques)
