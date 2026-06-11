module Steps {-# DEPRECATED "Superseded by Technique (Finding)" #-} where

import Algs.Algs (Algorithm)
import Board (CellInfo)
import Grid (Grid)

type Description = String

type Updates = [CellInfo]

data Step = Step Algorithm Description Updates

type Steps = [Step]

newtype Solution = Steps Grid
