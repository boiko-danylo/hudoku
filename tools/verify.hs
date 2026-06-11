-- Transcription verifier for corpus ingestion: reads puzzle lines from
-- stdin ("<id> <81 chars>" or bare "<81 chars>"), validates the givens,
-- solves with standardTechniques and reports outcome + contradiction signs.
--
--   python3 tools/grid-ocr.py page.heic --rotate 270 | stack runghc tools/verify.hs
import Board
import Checker
import ClassicBoard
import qualified Data.IntSet as IntSet
import Grid
import Solver

main :: IO ()
main = do
  input <- getContents
  mapM_ check (zip [1 :: Int ..] (filter (not . null) (lines input)))
  where
    check (i, line) =
      let (name, s) = case words line of
            [p] -> (show i, p)
            (n : p : _) -> (n, p)
            [] -> (show i, "")
       in verify name s

verify :: String -> String -> IO ()
verify name s
  | length s /= 81 = putStrLn (name ++ " BAD LENGTH " ++ show (length s))
  | otherwise = case readClassicGrid s of
      Nothing -> putStrLn (name ++ " PARSE FAIL (unknown character)")
      Just g
        | not (isBoardCorrect classicBoard g) ->
            putStrLn (name ++ " INVALID GIVENS (duplicate in a group)")
        | otherwise -> do
            let (outcome, final, journal) = runSolver standardTechniques classicBoard g
                contradictions = length [() | PossibleValues cs <- final, IntSet.null cs]
            putStrLn $
              unwords
                [ name,
                  show outcome,
                  "steps=" ++ show (length journal),
                  "valid=" ++ show (isBoardCorrect classicBoard final),
                  "contradictions=" ++ show contradictions
                ]
