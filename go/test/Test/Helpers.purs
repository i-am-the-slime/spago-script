module Test.Helpers (helpers) where

import Script.Prelude

import Data.Array as Array
import Data.String (Pattern(..))
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.Tuple.Nested ((/\))
import Effect.Ref as Ref
import Script.Environment (envOr, setEnv, setEnvUnlessSet, unsetEnv)
import Script.Files (absolutePath, changeDirectory, copyTree, filesEndingWith, filesUnder, readJSONFile, scriptDirectory, writeJSONFile)
import Script.Hyperfine (defaultBenchmark, hyperfine, measuredFrom)
import Script.Statistics (median, percentOf)
import Script.Table (alignedTable, markdownTable)
import Script.Text (decimals, linesOf, padLeft, padRight, substitute, trimEnd)
import Script.Baseline (Verdict(..), judge, readBaseline, writeBaseline)
import Foreign.Object as Object
import Script.Timing (timed, timedRuns)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)

helpers :: Spec Unit
helpers = describe "helpers" do
  filesSpec
  environmentSpec
  textSpec
  statisticsSpec
  tableSpec
  timingSpec
  hyperfineSpec
  baselineSpec

baselineSpec :: Spec Unit
baselineSpec = describe "Script.Baseline" do
  it "judges a score against the baseline's, higher is better" do
    judge 0.1 baseline "nqueens" 85.0 `shouldEqual` Regressed
    judge 0.1 baseline "nqueens" 95.0 `shouldEqual` Steady
    judge 0.1 baseline "nqueens" 115.0 `shouldEqual` Improved
    judge 0.1 baseline "cfold" 50.0 `shouldEqual` New

  it "keeps the baseline in a file, and starts empty without one" do
    removeFile file
    missing <- readBaseline file
    writeBaseline file baseline
    kept <- readBaseline file
    missing `shouldEqual` Object.empty
    kept `shouldEqual` baseline
  where
  baseline = Object.singleton "nqueens" 100.0
  file = "output/script-helpers-test/baseline.json"

filesSpec :: Spec Unit
filesSpec = describe "Script.Files" do
  it "finds every file below a directory, sorted, and those with a suffix" do
    removeDir tree
    mkdirp (tree / "b" / "deeper")
    write (tree / "z.go") "package z"
    write (tree / "b" / "a.txt") "a"
    write (tree / "b" / "deeper" / "c.go") "package c"
    everything <- filesUnder tree
    goFiles <- filesEndingWith ".go" tree
    everything `shouldEqual` [ tree / "b" / "a.txt", tree / "b" / "deeper" / "c.go", tree / "z.go" ]
    goFiles `shouldEqual` [ tree / "b" / "deeper" / "c.go", tree / "z.go" ]

  it "copies a whole tree" do
    removeDir copied
    copyTree tree copied
    copiedFiles <- filesUnder copied
    text <- read (copied / "b" / "deeper" / "c.go")
    Array.length copiedFiles `shouldEqual` 3
    text `shouldEqual` "package c"

  it "writes JSON indented and reads it back" do
    writeJSONFile (tree / "data.json") { name: "Ada", scores: [ 1, 2 ] }
    written <- read (tree / "data.json")
    back :: { name :: String, scores :: Array Int } <- readJSONFile (tree / "data.json")
    written `shouldSatisfy` String.contains (Pattern "\n  \"name\": \"Ada\"")
    written `shouldSatisfy` String.contains (Pattern "\n    1,\n    2\n  ]")
    CodeUnits.takeRight 2 written `shouldEqual` "}\n"
    back `shouldEqual` { name: "Ada", scores: [ 1, 2 ] }

  it "makes paths absolute" do
    absolute <- absolutePath "relative/file"
    here <- cwd # liftEffect
    absolute `shouldEqual` (here / "relative/file")

  it "changes the current directory" do
    before <- cwd # liftEffect
    changeDirectory tree
    inside <- cwd # liftEffect
    changeDirectory before
    inside `shouldEqual` (before / tree)

  it "knows the directory of the script spago-script-go started" do
    unsetEnv "SPAGO_SCRIPT_PATH"
    here <- cwd # liftEffect
    unstarted <- scriptDirectory
    setEnv "SPAGO_SCRIPT_PATH" "/home/ada/scripts/tidy.purs"
    started <- scriptDirectory
    unsetEnv "SPAGO_SCRIPT_PATH"
    unstarted `shouldEqual` here
    started `shouldEqual` "/home/ada/scripts"
  where
  tree = "output/script-helpers-test/tree"
  copied = "output/script-helpers-test/copied"

environmentSpec :: Spec Unit
environmentSpec = describe "Script.Environment" do
  it "sets a variable only when it isn't set yet" do
    unsetEnv "SPAGO_SCRIPT_HELPER"
    first <- setEnvUnlessSet "SPAGO_SCRIPT_HELPER" "first"
    second <- setEnvUnlessSet "SPAGO_SCRIPT_HELPER" "second"
    first `shouldEqual` "first"
    second `shouldEqual` "first"

  it "falls back when a variable isn't set, and programs see what the script sets" do
    unsetEnv "SPAGO_SCRIPT_HELPER"
    fallback <- envOr "SPAGO_SCRIPT_HELPER" "fallback"
    setEnv "SPAGO_SCRIPT_HELPER" "exported"
    seen <- x "sh" [ "-c", "echo $SPAGO_SCRIPT_HELPER" ]
    fallback `shouldEqual` "fallback"
    seen `shouldEqual` "exported"

textSpec :: Spec Unit
textSpec = describe "Script.Text" do
  it "substitutes each text, one pair after the other" do
    substitute [ "<!-- data -->" /\ "", "a" /\ "b", "b" /\ "c" ] "<p><!-- data -->a b</p>"
      `shouldEqual` "<p>c c</p>"

  it "splits lines without the empty one after a final newline" do
    linesOf "one\ntwo\n" `shouldEqual` [ "one", "two" ]
    linesOf "one\n\nthree" `shouldEqual` [ "one", "", "three" ]

  it "trims the end only" do
    trimEnd "  text \n\t" `shouldEqual` "  text"

  it "writes numbers with a fixed number of decimals" do
    decimals 2 3.14159 `shouldEqual` "3.14"
    decimals 0 104.4 `shouldEqual` "104"

  it "pads to a width" do
    padLeft 5 "42" `shouldEqual` "   42"
    padRight 5 "42" `shouldEqual` "42   "
    padLeft 1 "42" `shouldEqual` "42"

statisticsSpec :: Spec Unit
statisticsSpec = describe "Script.Statistics" do
  it "takes the middle value, or the mean of the middle two" do
    median [ 3.0, 1.0, 2.0 ] `shouldEqual` Just 2.0
    median [ 4.0, 1.0, 3.0, 2.0 ] `shouldEqual` Just 2.5
    median [] `shouldEqual` Nothing

  it "says how many percent a part is" do
    percentOf 50.0 200.0 `shouldEqual` 25.0

tableSpec :: Spec Unit
tableSpec = describe "Script.Table" do
  it "renders Markdown" do
    markdownTable [ "bench", "Go÷Iris" ] [ [ "nqueens", "104%" ], [ "rbtree", "97%" ] ]
      `shouldEqual` "| bench | Go÷Iris |\n|---|---|\n| nqueens | 104% |\n| rbtree | 97% |"

  it "lines up plain columns" do
    alignedTable [ "bench", "%" ] [ [ "nqueens", "104%" ], [ "cfold", "9%" ] ]
      `shouldEqual` "bench    %\nnqueens  104%\ncfold    9%"

timingSpec :: Spec Unit
timingSpec = describe "Script.Timing" do
  it "times an action and keeps its result" do
    measured <- timed (x "sleep" [ "0.05" ] $> "done")
    measured.result `shouldEqual` "done"
    measured.seconds `shouldSatisfy` (_ >= 0.05)

  it "runs warmups that don't count, then the counted runs" do
    count <- Ref.new 0 # liftEffect
    seconds <- timedRuns { warmups: 2, runs: 3 } (Ref.modify_ (_ + 1) count # liftEffect)
    total <- Ref.read count # liftEffect
    Array.length seconds `shouldEqual` 3
    total `shouldEqual` 5

hyperfineSpec :: Spec Unit
hyperfineSpec = describe "Script.Hyperfine" do
  it "summarises hyperfine's runs with medians" do
    let measured = measuredFrom { command: "true", measurements: [ run 0.3 2097152.0, run 0.1 1048576.0, run 0.2 3145728.0 ] }
    measured.medianWallSeconds `shouldEqual` 0.2
    measured.medianPeakMebibytes `shouldEqual` 2.0

  it "runs commands with hyperfine and reads back every run" do
    measured <- hyperfine defaultBenchmark { commands = [ "sleep 0.01", "true" ], runs = 3 }
    (_.command <$> measured) `shouldEqual` [ "sleep 0.01", "true" ]
    (Array.length <<< _.wallSeconds <$> measured) `shouldEqual` [ 3, 3 ]
  where
  run seconds bytes = { time_wall_clock: { value: seconds }, memory_peak_resident: { value: bytes } }
