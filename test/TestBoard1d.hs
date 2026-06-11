module TestBoard1d where

import Board

-- | A one-dimensional board: n cells forming a single all-different group.
lineBoard :: Int -> Board
lineBoard n = Board 1 n [map (\x -> Position [x]) [1 .. n]] (map (\x -> (x, Position [x])) [1 .. n])

testBoard1dSize = 5

testBoard1d = lineBoard testBoard1dSize
