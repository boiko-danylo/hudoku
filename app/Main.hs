module Main where

import ClassicBoard
import Data.Maybe (fromJust)
import Grid
import GridShowers
import Solver
import System.Exit

harderGrid :: Grid
harderGrid =
  fromJust . readClassicGrid $
    concat
      [ "5...1.7..",
        "8........",
        "2....35..",
        "..1.9..6.",
        "3..851..7",
        ".8..4.3..",
        "..51....9",
        "........3",
        "..4.3...2"
      ]

main :: IO ()
main = do
  let (outcome, grid, journal) = runSolver standardTechniques classicBoard harderGrid
  putStrLn ("Outcome: " ++ show outcome)
  putStrLn ("Steps:   " ++ show (length journal))
  putStrLn (showGridPV classicVariant grid)
  exitSuccess
