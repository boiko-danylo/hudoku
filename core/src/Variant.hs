module Variant where

import Board

-- Presentation and rules context kept outside the solving core
-- (ADR-0002/0007): a Variant bundles what a UI or renderer needs.
-- New shapes (3D, irregular) become new Layout constructors.

data Layout = Layout2D
  { layoutWidth :: Size,
    layoutHeight :: Size -- row-major: index = y * width + x
  }
  deriving (Show, Eq)

data Variant = Variant
  { variantBoard :: Board,
    variantLayout :: Layout
  }
