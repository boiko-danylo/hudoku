module CorpusTest (corpusTests) where

import Checker
import ClassicBoard
import Data.Aeson
import qualified Data.ByteString.Lazy as B
import qualified Data.IntSet as IntSet
import Grid
import Solver
import Test.Tasty
import Test.Tasty.HUnit

-- The progress tracker: every known puzzle is solved on every test run and
-- the outcome must match the recorded expectation. When a new technique
-- lands, flip the freshly conquered "stuck" entries to "solved" in
-- corpus/*.json — the git history of that file is the solver's scoreboard.

data Mission = Mission
  { missionId :: String,
    difficulty :: String,
    puzzle :: String,
    expect :: String
  }

instance FromJSON Mission where
  parseJSON = withObject "Mission" $ \o ->
    Mission <$> o .: "id" <*> o .: "difficulty" <*> o .: "puzzle" <*> o .: "expect"

corpusTests :: IO TestTree
corpusTests = do
  decoded <- eitherDecode <$> B.readFile "corpus/magazine.json"
  pure $ case decoded of
    Left err -> testCase "corpus parses" (assertFailure err)
    Right missions -> testGroup "Corpus (magazine)" (map missionTest missions)

missionTest :: Mission -> TestTree
missionTest m = testCase (missionId m ++ " (" ++ difficulty m ++ ") -> " ++ expect m) $ do
  grid <- maybe (assertFailure "puzzle does not parse") pure (readClassicGrid (puzzle m))
  isBoardCorrect classicBoard grid @? "invalid givens"
  let (outcome, final, _) = runSolver standardTechniques classicBoard grid
  isBoardCorrect classicBoard final @? "solver produced an invalid grid"
  null [() | PossibleValues cs <- final, IntSet.null cs]
    @? "contradiction: a cell lost all candidates"
  show outcome @?= expectedOutcome
  where
    expectedOutcome = case expect m of
      "solved" -> "Solved"
      "stuck" -> "Stuck"
      other -> other
