module Script.Text
  ( substitute
  , linesOf
  , trimEnd
  , padLeft
  , padRight
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), Replacement(..))
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.Tuple.Nested (type (/\), (/\))

-- | Replaces every occurrence of each text with its replacement, one pair after the other, as a
-- | `sed -e s|…|…|g -e …` does without the regular expressions.
substitute :: Array (String /\ String) -> String -> String
substitute replacements text = foldl replaceOne text replacements
  where
  replaceOne replaced (find /\ replacement) = String.replaceAll (Pattern find) (Replacement replacement) replaced

-- | The lines of a text, without a last empty one after a final newline.
linesOf :: String -> Array String
linesOf text = dropLastEmpty (String.split (Pattern "\n") text)
  where
  dropLastEmpty lines = case Array.unsnoc lines of
    Just { init, last: "" } -> init
    _ -> lines

-- | The text without blanks and newlines at its end.
trimEnd :: String -> String
trimEnd text = case CodeUnits.charAt (CodeUnits.length text - 1) text of
  Just last | isBlank last -> trimEnd (CodeUnits.dropRight 1 text)
  _ -> text
  where
  isBlank character = character == ' ' || character == '\n' || character == '\t' || character == '\r'

-- | The text with blanks in front, so it is at least that wide, for right-aligned columns.
padLeft :: Int -> String -> String
padLeft width text = blanks (width - String.length text) <> text

-- | The text with blanks after it, so it is at least that wide, for left-aligned columns.
padRight :: Int -> String -> String
padRight width text = text <> blanks (width - String.length text)

blanks :: Int -> String
blanks count = CodeUnits.fromCharArray (Array.replicate count ' ')
