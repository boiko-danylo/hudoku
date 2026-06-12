module CorpusTest (corpusTests) where

import Checker
import ClassicBoard
import Data.Aeson
import qualified Data.ByteString.Lazy as B
import qualified Data.IntSet as IntSet
import Data.List (isSuffixOf, sort)
import Grid
import Solver
import System.Directory (listDirectory)
import System.FilePath (takeBaseName, (</>))
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
    expect :: String,
    -- some sources publish the full solution; when present, every value
    -- the solver places is checked against it (even on stuck puzzles)
    solution :: Maybe String
  }

instance FromJSON Mission where
  parseJSON = withObject "Mission" $ \o ->
    Mission
      <$> o .: "id"
      <*> o .: "difficulty"
      <*> o .: "puzzle"
      <*> o .: "expect"
      <*> o .:? "solution"

-- tests run with cwd = core/; the corpus lives at the repo root
corpusDir :: FilePath
corpusDir = "../corpus"

corpusTests :: IO TestTree
corpusTests = do
  files <- sort . filter (".json" `isSuffixOf`) <$> listDirectory corpusDir
  testGroup "Corpus" <$> mapM fileTests files

fileTests :: FilePath -> IO TestTree
fileTests file = do
  decoded <- eitherDecode <$> B.readFile (corpusDir </> file)
  pure $ case decoded of
    Left err -> testCase (file ++ " parses") (assertFailure err)
    Right missions -> testGroup (takeBaseName file) (map missionTest missions)

missionTest :: Mission -> TestTree
missionTest m = testCase (missionId m ++ " (" ++ difficulty m ++ ") -> " ++ expect m) $ do
  grid <- maybe (assertFailure "puzzle does not parse") pure (readClassicGrid (puzzle m))
  isBoardCorrect classicBoard grid @? "invalid givens"
  let (outcome, final, _) = runSolver standardTechniques classicBoard grid
  isBoardCorrect classicBoard final @? "solver produced an invalid grid"
  null [() | PossibleValues cs <- final, IntSet.null cs]
    @? "contradiction: a cell lost all candidates"
  case solution m of
    Nothing -> pure ()
    Just sol ->
      and [show v == [c] | (CellValue v, c) <- zip final sol]
        @? "a placed value disagrees with the known solution"
  show outcome @?= expectedOutcome
  where
    expectedOutcome = case expect m of
      "solved" -> "Solved"
      "stuck" -> "Stuck"
      other -> other
