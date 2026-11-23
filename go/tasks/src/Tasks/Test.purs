-- | Runs the Go flavour's tests: the Script.Prelude specs, the CLI tests and the prompt tests.
-- | Run it in spago-script's go directory:
-- |
-- |   iris run --go -p spago-script-go-tasks --entry Tasks.Test.main
-- |
-- | `IRIS` names the iris binary, `IRIS_GO` a local iris-go checkout to build against.
module Tasks.Test (main) where

import Script.Prelude

import Data.Array as Array
import Data.Foldable (for_)
import Data.Maybe (fromMaybe)
import Data.String (Pattern(..))
import Data.String as String
import Data.Tuple.Nested ((/\))
import Script.Environment (envOr, setEnv)
import Script.Files (absolutePath)
import Script.Text (linesOf, substitute)
import Tasks.Build (buildSpagoScriptGo, irisGoVersion)

main :: Effect Unit
main = run do
  iris <- envOr "IRIS" "iris"
  log "== Script.Prelude specs"
  preludeSpecs iris
  log "== CLI"
  binary <- absolutePath "bin/spago-script-go"
  buildSpagoScriptGo binary
  _ <- xWith "go" [ "test", "-count=1", "." ] (_ { cwd = Just ("cmd" / "spago-script-go"), stdout = Just inherit, stderr = Just inherit })
  log "== prompts"
  promptTests binary

-- | Compiles Test.Main to Go and runs it.
preludeSpecs :: forall r. String -> Om r () Unit
preludeSpecs iris = do
  localRuntime <- lookupEnv "IRIS_GO" # liftEffect
  mkdirp "out"
  write ("out" / "go.mod") (specsGoModule localRuntime)
  _ <- x iris [ "go", "--package", "spago-script-go", "--entry", "Test.Main.main", "out" ]
  setEnv "GOFLAGS" "-mod=mod"
  _ <- xWith "go" [ "build", "-o", "spec-runner", "." ] (_ { cwd = Just "out" })
  xPipe ("out" / "spec-runner") ([] :: Array String)

specsGoModule :: Maybe FilePath -> String
specsGoModule localRuntime = String.joinWith "\n"
  ( [ "module spago-script-go-test"
    , ""
    , "go 1.27.0"
    , ""
    , "require ("
    , "\tgithub.com/i-am-the-slime/iris-go " <> irisGoVersion
    , "\tmodernc.org/sqlite v1.62.0"
    , ")"
    ]
      <> maybe [] (\runtime -> [ "", "replace github.com/i-am-the-slime/iris-go => " <> runtime ]) localRuntime
      <> [ "" ]
  )

-- | Runs the Bun flavour's prompt tests (test/pty) against spago-script-go: each `expect` line of
-- | test/pty/run, with the Bun runner's path in the expectation swapped for the binary.
promptTests :: forall r. FilePath -> Om r () Unit
promptTests binary = do
  runner <- read (".." / "test" / "pty" / "run")
  scratch <- mkdtemp "/tmp/spago-script-go-prompts-"
  for_ (Array.mapMaybe expectation (linesOf runner)) (runOne scratch)
  removeDir scratch
  log "all prompt tests passed"
  where
  expectation line = case String.split (Pattern " ") line of
    [ "expect", expectFile, script ] | String.take 9 expectFile == "test/pty/" -> Just { expectFile, script }
    _ -> Nothing

  runOne scratch { expectFile, script } = do
    original <- read (".." / expectFile)
    let forGo = scratch / baseName expectFile
    write forGo (substitute [ bunRunner /\ binary ] original)
    log ("== " <> baseName expectFile <> " " <> baseName script)
    _ <- xWith "expect" [ forGo, script ] (_ { cwd = Just ".." })
    pure unit

  bunRunner = "/Users/mark/code/spago-script/bin/spago-script.js"

  baseName path = fromMaybe path (Array.last (String.split (Pattern "/") path))
