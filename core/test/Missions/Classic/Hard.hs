module Missions.Classic.Hard (tests) where

import qualified Data.ByteString.Lazy as B
import GHC.Generics
import Control.Applicative
import Control.Monad
import Data.Aeson
import Data.Text
import Test.Tasty
import Test.Tasty.HUnit



--  Taken from 
-- curl 'https://sudoku.com/api/level/hard' 

tests = testGroup "Classic Hard missions tests"  [ ] 


-- data Mission =
    -- Mission { id :: Int
            -- , mission :: Text
            -- , solution :: Text
    -- } deriving (Show,Generic)

-- instance FromJSON Mission


-- jsonFile :: FilePath
-- jsonFile = "hard.json"

-- getJSON :: IO B.ByteString
-- getJSON = B.readFile jsonFile