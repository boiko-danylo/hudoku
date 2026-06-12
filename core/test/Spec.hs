import qualified BoardTest
import qualified CheckerTest
import qualified CorpusTest
import ClassicBoard
import Data.Maybe (fromJust)
import qualified GridShowersTest
import qualified GridTest
import qualified Hodoku.ReglibTest
import Solver
import qualified SolverTest
import qualified TechniqueTest
import qualified Techniques.HiddenSubsetsTest
import qualified Techniques.NakedSinglesTest
import qualified Techniques.NakedSubsetsTest
import qualified Techniques.PeerEliminationTest
import Test.Tasty
import Test.Tasty.HUnit

main = do
  corpus <- CorpusTest.corpusTests
  reglib <- Hodoku.ReglibTest.reglibTests
  defaultMain (tests corpus reglib)

tests corpus reglib =
  testGroup
    "All tests"
    [ corpus,
      reglib,
      endToEndTests,
      BoardTest.tests,
      CheckerTest.tests,
      GridTest.tests,
      GridShowersTest.tests,
      TechniqueTest.tests,
      Techniques.NakedSubsetsTest.tests,
      Techniques.HiddenSubsetsTest.tests,
      Techniques.NakedSinglesTest.tests,
      Techniques.PeerEliminationTest.tests,
      SolverTest.tests
    ]

endToEndTests =
  testGroup
    "End-to-end solving with standardTechniques"
    [ solves "simplest" "...1.5.68......7.19.1....3...7.26...5.......3...87.4...3....8.51.5......79.4.1...",
      solves "medium" ".......1.4.........2...........5.4.7..8...3....1.9....3..4..2...5.1........8.6...",
      solves "harder" $
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
          ],
      solves "harder 2" "....8..7..58.3.1............26....9.4.......67...293....7...9..1..2.3....6.....54"
    ]

solves :: String -> String -> TestTree
solves name puzzle = testCase (name ++ " grid solved") $ outcome @?= Solved
  where
    (outcome, _, _) = runSolver standardTechniques classicBoard (fromJust (readClassicGrid puzzle))
