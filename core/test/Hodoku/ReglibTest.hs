-- | Runs HoDoKu's regression library (technique-labeled cases with exact
-- expected conclusions) against our techniques. The fixture is fetched,
-- not vendored (GPLv3) — see corpus/fetch-fixtures.sh; without it the
-- group collapses to a single no-op test.
module Hodoku.ReglibTest (reglibTests) where

import Board
import ClassicBoard (classicBoard)
import qualified Data.IntSet as IntSet
import Data.List (foldl', sortOn)
import qualified Data.Map.Strict as Map
import Data.Ord (Down (..))
import Grid
import Hodoku.Reglib
import System.Directory (doesFileExist)
import Technique
import Techniques.HiddenSubsets
import Techniques.LockedCandidates
import Techniques.NakedSingles
import Techniques.NakedSubsets
import Test.Tasty
import Test.Tasty.HUnit

fixturePath :: FilePath
fixturePath = "../corpus/fixtures/reglib-1.3.txt"

-- HoDoKu technique codes covered by our current techniques. Everything
-- not in this table is reported as backlog — the library doubles as a
-- ranked roadmap of techniques still to build.
techniqueFor :: String -> Maybe Technique
techniqueFor code = case code of
  "0000" -> Just nakedSingles -- Full House: one open cell left in a group
  "0003" -> Just nakedSingles
  "0002" -> Just hiddenSingles
  "0100" -> Just lockedCandidates -- pointing and claiming are one rule
  "0101" -> Just lockedCandidates
  "0200" -> Just (nakedSubsets 2)
  "0201" -> Just (nakedSubsets 3)
  "0202" -> Just (nakedSubsets 4)
  "0210" -> Just (hiddenSubsets 2)
  "0211" -> Just (hiddenSubsets 3)
  "0212" -> Just (hiddenSubsets 4)
  _ -> Nothing

reglibTests :: IO TestTree
reglibTests = do
  exists <- doesFileExist fixturePath
  if not exists
    then
      pure $
        testCase
          "HoDoKu reglib: fixture missing, skipped (run corpus/fetch-fixtures.sh)"
          (pure ())
    else do
      src <- readFile fixturePath
      let (errors, cases) = parseLibrary src
          labels = labelTable src
          runnable =
            Map.fromListWith
              (flip (++))
              [(caseTechnique c, [(t, c)]) | c <- cases, Just t <- [techniqueFor (caseTechnique c)]]
          backlog =
            Map.fromListWith
              (+)
              [(caseTechnique c, 1 :: Int) | c <- cases, Nothing <- [techniqueFor (caseTechnique c)]]
      putStrLn (backlogSummary labels (sum (map length (Map.elems runnable))) backlog)
      pure $
        testGroup "HoDoKu reglib" $
          testCase "every library line parses" (null errors @? unlines (take 3 errors))
            : [ testGroup
                  (code ++ " " ++ Map.findWithDefault "?" code labels)
                  (zipWith caseTest [1 ..] tcs)
                | (code, tcs) <- Map.toList runnable
              ]

-- The library's own comment header carries the code -> name table
-- ("#0200: Naked Pair"); reuse it instead of duplicating it here.
labelTable :: String -> Map.Map String String
labelTable src =
  Map.fromList
    [ (code, drop 2 rest)
      | '#' : l <- lines src,
        let (code, rest) = break (== ':') l,
        length code == 4,
        all (`elem` ['0' .. '9']) code
    ]

backlogSummary :: Map.Map String String -> Int -> Map.Map String Int -> String
backlogSummary labels nRun backlog =
  "HoDoKu reglib: "
    ++ show nRun
    ++ " cases runnable; biggest backlog: "
    ++ unwords
      [ code ++ " " ++ Map.findWithDefault "?" code labels ++ " (" ++ show n ++ ")"
        | (code, n) <- take 5 (sortOn (Down . snd) (Map.toList backlog))
      ]

caseTest :: Int -> (Technique, Case) -> TestTree
caseTest k (tech, c) = testCase name $ do
  let findings = tech classicBoard grid
      updates = concatMap findingUpdates findings
  if caseFailCase c
    then null findings @? "fail case: the technique must not fire here"
    else do
      mapM_ (expectElimination updates) (caseEliminations c)
      mapM_ (expectPlacement grid updates) (casePlacements c)
  where
    grid = pencilMarks classicBoard c
    name =
      "#" ++ show k ++ " candidates " ++ concatMap show (caseCandidates c)

-- r3c6<>4 is satisfied by any Eliminate covering value 4 at that cell
expectElimination :: [CellUpdate] -> Mark -> Assertion
expectElimination updates m =
  or [markIndex m == i && markValue m `IntSet.member` cs | Eliminate i cs <- updates]
    @? "missing elimination " ++ showMark "<>" m

-- A placement is satisfied by a literal Place, or by an elimination that
-- shrinks the cell to exactly that single candidate (our hidden single
-- eliminates; the follow-up naked single does the placing).
expectPlacement :: Grid -> [CellUpdate] -> Mark -> Assertion
expectPlacement grid updates m =
  (Place i v `elem` updates || any shrinksToV updates)
    @? "missing placement " ++ showMark "=" m
  where
    i = markIndex m
    v = markValue m
    shrinksToV (Eliminate j cs)
      | j == i,
        PossibleValues pv <- grid !! i =
          pv `IntSet.difference` cs == IntSet.singleton v
    shrinksToV _ = False

showMark :: String -> Mark -> String
showMark op m = "r" ++ show (markRow m) ++ "c" ++ show (markCol m) ++ op ++ show (markValue m)

-- | Reconstruct the exact pencil-mark state of a case: solved cells from
--   the grid field, open cells carry the domain minus solved peers
--   (HoDoKu's implicit baseline), then the explicit deletions on top.
pencilMarks :: Board -> Case -> Grid
pencilMarks board c = foldl' (flip applyUpdate) base deletions
  where
    specs = caseCells c
    solveds = map specValue specs
    specValue (Given v) = Just v
    specValue (Placed v) = Just v
    specValue Open = Nothing
    base = zipWith cellAt [0 ..] specs
    cellAt _ (Given v) = CellValue v
    cellAt _ (Placed v) = CellValue v
    cellAt i Open = PossibleValues (boardValues board `IntSet.difference` banned i)
    banned i =
      IntSet.fromList
        [ v
          | g <- boardGroups board,
            i `IntSet.member` groupCells g,
            j <- IntSet.toList (groupCells g),
            Just v <- [solveds !! j]
        ]
    deletions =
      [Eliminate (markIndex m) (IntSet.singleton (markValue m)) | m <- caseDeleted c]
