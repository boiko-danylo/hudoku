-- import qualified Algs.NakedSubsetsTest
-- import qualified Algs.HiddenSubsetsTest

import Algs.HiddenSets
import Board
import qualified BoardTest
import ClassicBoard
import Data.Maybe
import qualified GameTest
import Grid
import qualified TechniqueTest
import qualified Techniques.NakedSubsetsTest
import Test.Tasty
import Test.Tasty.HUnit

-- import Missions.Classic.Hard

main = defaultMain tests

tests =
  testGroup
    "All tests"
    [ basicTests,
      BoardTest.tests,
      GameTest.tests,
      -- Algs.NakedSubsetsTest.tests,
      -- Algs.HiddenSubsetsTest.tests
      TechniqueTest.tests,
      Techniques.NakedSubsetsTest.tests
    ]

basicTests =
  testGroup
    "Basic tests"
    [ simplestTestCase,
      mediumTestCase
      -- , harderTestCase
      -- , harderTestCase2
    ]

-- simple
simpleSolver = updatePossibleValues classicBoard . refreshGridValues

simpleGrid = readGridWith classicInit "...1.5.68......7.19.1....3...7.26...5.......3...87.4...3....8.51.5......79.4.1..."

simplestTestCase = testCase "Simplest classic grid solved" $ assertBool "Not solved" $ isGridSolvedWith simpleGrid simpleSolver

-- medium
mediumSolver = refreshGridValues . updateUniqueValues classicBoard . updatePossibleValues classicBoard

mediumGrid = readGridWith classicInit ".......1.4.........2...........5.4.7..8...3....1.9....3..4..2...5.1........8.6..."

mediumTestCase = testCase "Medium classic grid solved" $ assertBool "Not solved" $ isGridSolvedWith mediumGrid mediumSolver

-- harder
harderGrid =
  readGridWith classicInit $
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

{-
harderTestCase = testCase "Harder classic grid solved" $ assertBool "Not solved" $ isGridSolvedWith harderGrid solver
  where
    solver = mediumSolver . ss2 . ss3
    ss2 = nakedSubsetsN classicBoard 2
    ss3 = nakedSubsetsN classicBoard 3

harderTestCase2 = testCase "Harder calssic case 2" $ assertBool "Not solved" $ isGridSolvedWith grid solver
  where
    grid = readGridWith classicInit "....8..7..58.3.1............26....9.4.......67...293....7...9..1..2.3....6.....54"
    solver = mediumSolver . ss2 . hs2
    ss2 = nakedSubsetsN classicBoard 2
    hs2 = hiddenSubsetsN classicBoard 2
-}
-- helpers
classicGridSolved = gridSolved classicBoard

classicInitPossibleValues = initPossibleValues' classicBoard

isGridSolvedWith :: Grid -> (Grid -> Grid) -> Bool
isGridSolvedWith g f = classicGridSolved $ recursiveUpdateWith f g
