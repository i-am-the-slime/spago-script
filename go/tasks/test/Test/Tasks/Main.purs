module Test.Tasks.Main (main) where

import Script.Prelude

import Data.Identity (Identity(..))
import Data.Newtype (un)
import Data.String as String
import Tasks.Manifest (dependencies, extraPackageRef, packageSection, registryVersion)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (defaultConfig, evalSpecT)
import Test.Spec.Summary (successful)

main :: Effect Unit
main = launch do
  results <- un Identity (evalSpecT (defaultConfig { exit = false }) [ consoleReporter ] manifestSpec)
  unless (successful results) (exit 1 # liftEffect)

manifestSpec :: Spec Unit
manifestSpec = describe "Tasks.Manifest" do
  it "keeps the package without its tests and workspace" do
    packageSection manifest `shouldEqual` String.joinWith "\n"
      [ "package:"
      , "  name: spago-script-go"
      , "  dependencies:"
      , "    - aff"
      , "    - go-io"
      , "    - yoga-json: \">=5.0.0 <6.0.0\""
      , "  description: after the tests"
      , ""
      ]

  it "lists the dependencies without their ranges" do
    dependencies manifest `shouldEqual` [ "aff", "go-io", "yoga-json" ]

  it "finds the registry version and the ref an extra package is pinned to" do
    registryVersion manifest `shouldEqual` Just "77.9.0"
    extraPackageRef "go-io" manifest `shouldEqual` Just "353775e4"
    extraPackageRef "go-os" manifest `shouldEqual` Nothing
  where
  manifest = String.joinWith "\n"
    [ "package:"
    , "  name: spago-script-go"
    , "  dependencies:"
    , "    - aff"
    , "    - go-io"
    , "    - yoga-json: \">=5.0.0 <6.0.0\""
    , "  test:"
    , "    main: Test.Main"
    , "    dependencies:"
    , "      - spec"
    , "  description: after the tests"
    , "workspace:"
    , "  packageSet:"
    , "    registry: 77.9.0"
    , "  extraPackages:"
    , "    go-io:"
    , "      git: https://github.com/i-am-the-slime/purescript-go.git"
    , "      ref: 353775e4"
    , "      subdir: packages/go-io"
    , ""
    ]
