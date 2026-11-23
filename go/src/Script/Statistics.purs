module Script.Statistics
  ( median
  , percentOf
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))

-- | The middle value, or the mean of the two middle ones; nothing for no values.
median :: Array Number -> Maybe Number
median values = case Array.length sorted of
  0 -> Nothing
  count
    | count `mod` 2 == 1 -> Array.index sorted (count / 2)
    | otherwise -> meanOf <$> Array.index sorted (count / 2 - 1) <*> Array.index sorted (count / 2)
  where
  sorted = Array.sort values
  meanOf lower upper = (lower + upper) / 2.0

-- | How many percent the part is of the whole: `percentOf 50.0 200.0` is 25.0.
percentOf :: Number -> Number -> Number
percentOf part whole = 100.0 * part / whole
