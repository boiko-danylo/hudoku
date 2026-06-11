module GridShowers where

import Grid
import Text.PrettyPrint.Boxes
import Variant
import Prelude hiding ((<>))

-- | Render a grid with candidates, shaped by the variant's layout.
showGridPV :: Variant -> Grid -> String
showGridPV v grid = render $ foldl (//) nullBox rowBoxes
  where
    Layout2D w h = variantLayout v
    rowBoxes = [rowBox y | y <- [0 .. h - 1]]
    rowBox y = foldl (<>) nullBox [text (showCellData (grid !! (y * w + x))) | x <- [0 .. w - 1]]
