module Script.Hyperfine
  ( Benchmark
  , Measured
  , defaultBenchmark
  , hyperfine
  , measuredFrom
  ) where

import Script.Prelude

import Data.Array as Array
import Data.Maybe (fromMaybe)
import Script.Files (readJSONFile)
import Script.Statistics (median)

-- | What `hyperfine` runs: each command (split at blanks, no shell) `runs` times after `warmups`
-- | runs it doesn't count, with standard input from `input` when there is one.
type Benchmark =
  { commands :: Array String
  , runs :: Int
  , warmups :: Int
  , input :: Maybe FilePath
  }

defaultBenchmark :: Benchmark
defaultBenchmark = { commands: [], runs: 7, warmups: 1, input: Nothing }

-- | Every run of one command: wall time in seconds, peak resident memory in bytes, and the medians.
type Measured =
  { command :: String
  , wallSeconds :: Array Number
  , peakBytes :: Array Number
  , medianWallSeconds :: Number
  , medianPeakMebibytes :: Number
  }

-- | Runs the benchmark with `hyperfine` and reads back what it measured, in the order of the
-- | commands. The commands' output goes nowhere.
hyperfine :: forall m. MonadAff m => Benchmark -> m (Array Measured)
hyperfine benchmark = do
  scratch <- mkdtemp "/tmp/hyperfine-"
  let exported = scratch / "results.json"
  x_ "hyperfine" (options exported <> benchmark.commands)
  results :: HyperfineExport <- readJSONFile exported
  removeDir scratch
  pure (measuredFrom <$> results.results)
  where
  options exported =
    [ "-N", "--warmup", show benchmark.warmups, "--runs", show benchmark.runs, "--output=null", "--export-json", exported ]
      <> maybe [] (\file -> [ "--input", file ]) benchmark.input

-- | What hyperfine 2 writes with `--export-json`, as far as it matters here.
type HyperfineExport = { results :: Array HyperfineResult }

type HyperfineResult =
  { command :: String
  , measurements :: Array { time_wall_clock :: { value :: Number }, memory_peak_resident :: { value :: Number } }
  }

measuredFrom :: HyperfineResult -> Measured
measuredFrom { command, measurements } =
  { command
  , wallSeconds
  , peakBytes
  , medianWallSeconds: fromMaybe 0.0 (median wallSeconds)
  , medianPeakMebibytes: inMebibytes (fromMaybe 0.0 (median peakBytes))
  }
  where
  inMebibytes bytes = div bytes 1048576.0
  wallSeconds = _.time_wall_clock.value <$> measurements
  peakBytes = _.memory_peak_resident.value <$> measurements
