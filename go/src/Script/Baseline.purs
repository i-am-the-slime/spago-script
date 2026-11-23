-- | Scores kept in a JSON file to compare later runs with, such as benchmark ratios, where a
-- | higher score is better.
module Script.Baseline
  ( Baseline
  , Verdict(..)
  , readBaseline
  , writeBaseline
  , judge
  , verdictLabel
  ) where

import Script.Prelude

import Foreign.Object (Object)
import Foreign.Object as Object
import Script.Files (readJSONFile, writeJSONFile)

-- | A score for each name.
type Baseline = Object Number

data Verdict = New | Steady | Improved | Regressed

derive instance Eq Verdict

instance Show Verdict where
  show = verdictLabel

-- | The baseline in the file, or none when there is no file yet.
readBaseline :: forall m. MonadAff m => FilePath -> m Baseline
readBaseline path = do
  there <- fileExists path
  if there then readJSONFile path else pure Object.empty

writeBaseline :: forall m. MonadAff m => FilePath -> Baseline -> m Unit
writeBaseline = writeJSONFile

-- | How a score compares with the baseline's: it regressed when it fell by more than `tolerance`
-- | (0.1 is 10 %) of the baseline's, improved when it rose by more.
judge :: Number -> Baseline -> String -> Number -> Verdict
judge tolerance baseline name score = case Object.lookup name baseline of
  Nothing -> New
  Just before
    | score < before * (1.0 - tolerance) -> Regressed
    | score > before * (1.0 + tolerance) -> Improved
    | otherwise -> Steady

verdictLabel :: Verdict -> String
verdictLabel = case _ of
  New -> "new"
  Steady -> ""
  Improved -> "improved"
  Regressed -> "REGRESSED"
