module Script.Table
  ( markdownTable
  , alignedTable
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (maximum)
import Data.Maybe (fromMaybe)
import Data.String as String
import Script.Text (padRight, trimEnd)

-- | A Markdown table with the headers on top.
markdownTable :: Array String -> Array (Array String) -> String
markdownTable headers rows = String.joinWith "\n" ([ row headers, separator ] <> (row <$> rows))
  where
  row cells = "| " <> String.joinWith " | " cells <> " |"
  separator = "|" <> String.joinWith "|" ("---" <$ headers) <> "|"

-- | A plain text table whose columns line up, the headers on top, two blanks between columns.
alignedTable :: Array String -> Array (Array String) -> String
alignedTable headers rows = String.joinWith "\n" (row <$> allRows)
  where
  allRows = [ headers ] <> rows
  row cells = trimEnd (String.joinWith "  " (Array.mapWithIndex padToColumn cells))
  padToColumn column cell = padRight (widthOf column) cell
  widthOf column = fromMaybe 0 (maximum (String.length <<< cellAt column <$> allRows))
  cellAt column cells = fromMaybe "" (Array.index cells column)
