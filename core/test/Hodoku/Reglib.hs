-- | Parser for the HoDoKu regression library format (reglib-1.3.txt):
--
--   :<technique>:<candidates>:<grid>:<deleted>:<eliminations>:<placements>:
--
-- Positions are encoded as three glued digits <value><row><col>:
-- "436" means "candidate 4 at r3c6". The grid is 81 cells where a bare
-- digit is a given, '+digit' a solver-placed value and '.' an open cell;
-- <deleted> lists candidates already eliminated, so grid + deleted
-- reproduce the exact pencil-mark state the technique must act on.
module Hodoku.Reglib
  ( Case (..),
    CellSpec (..),
    Mark (..),
    markIndex,
    parseLibrary,
  )
where

import Data.Char (digitToInt, isSpace)
import Data.Either (partitionEithers)
import Data.List (isPrefixOf)
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char

-- Parsec's two fixed parameters: the custom error type (Void — we add
-- none) and the input stream type.
type Parser = Parsec Void String

data Case = Case
  { caseTechnique :: String, -- base code, e.g. "0200" = Naked Pair
    caseFailCase :: Bool, -- variant "-x": the technique must NOT fire
    caseCandidates :: [Int], -- the digits the technique acts on
    caseCells :: [CellSpec], -- exactly 81
    caseDeleted :: [Mark], -- pencil marks removed from the start state
    caseEliminations :: [Mark], -- expected removals (xor placements)
    casePlacements :: [Mark] -- expected placements
  }
  deriving (Show)

data CellSpec = Given Int | Placed Int | Open
  deriving (Show, Eq)

data Mark = Mark
  { markValue :: Int,
    markRow :: Int, -- 1..9
    markCol :: Int -- 1..9
  }
  deriving (Show, Eq)

-- Row-major cell index of a mark, matching Board.GridIndex
markIndex :: Mark -> Int
markIndex m = (markRow m - 1) * 9 + (markCol m - 1)

-- A sudoku digit; '0' is not a value
value :: Parser Int
value = digitToInt <$> oneOf ['1' .. '9']

-- Three digits glued together — parsers compose like values
mark :: Parser Mark
mark = Mark <$> value <*> value <*> value

-- Zero or more marks, blank-separated (fields are often empty)
marks :: Parser [Mark]
marks = mark `sepBy` char ' '

cellSpec :: Parser CellSpec
cellSpec =
  choice
    [ Placed <$> (char '+' *> value),
      Given <$> value,
      Open <$ char '.'
    ]

-- "0200", "0708-1", "0610-x"
technique :: Parser (String, Maybe String)
technique = (,) <$> some alphaNumChar <*> optional (char '-' *> some alphaNumChar)

caseP :: Parser Case
caseP =
  mkCase
    <$> (char ':' *> technique)
    <*> (char ':' *> many value)
    <*> (char ':' *> count 81 cellSpec)
    <*> (char ':' *> marks)
    <*> (char ':' *> marks)
    <*> (char ':' *> marks)
    -- ':' then the optional <extra> field (chain length, for chain
    -- techniques); a handful of library lines drop the trailing colon
    <* optional (char ':' *> many digitChar)
    <* eof
  where
    mkCase (base, variant) =
      Case base (variant == Just "x")

-- | Parse every test-case line of a library file; comments ('#') and
--   blank lines are skipped. Left = pretty error per unparseable line.
parseLibrary :: String -> ([String], [Case])
parseLibrary src =
  partitionEithers
    [ either (Left . errorBundlePretty) Right
        (parse caseP ("reglib line " ++ show n) line)
      | (n, line) <- zip [1 :: Int ..] (lines src),
        not (skippable line)
    ]
  where
    skippable l = all isSpace l || "#" `isPrefixOf` l
