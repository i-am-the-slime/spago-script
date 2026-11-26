-- | Builds the spago-script-go binary with Script.Prelude for Go and purescript-go's packages
-- | inside. Run it in spago-script's go directory:
-- |
-- |   googoo run --go -p spago-script-go-tasks --entry Tasks.Build.main -- [OUTPUT]
-- |
-- | OUTPUT defaults to bin/spago-script-go. `PURESCRIPT_GO` may name a local purescript-go
-- | checkout to take the packages from instead of the commit spago.yaml pins.
module Tasks.Build
  ( main
  , buildSpagoScriptGo
  , irisGoVersion
  ) where

import Script.Prelude

import Data.Array as Array
import Data.Foldable (for_)
import Data.Maybe (fromMaybe)
import Data.String (Pattern(..))
import Data.String as String
import Effect.Aff (throwError)
import Effect.Exception (error)
import Script.Files (absolutePath, copyTree)
import Tasks.Manifest (dependencies, extraPackageRef, packageSection, registryVersion)

main :: Effect Unit
main = run do
  given <- args # liftEffect
  output <- absolutePath (fromMaybe defaultOutput (Array.head given))
  buildSpagoScriptGo output

defaultOutput :: FilePath
defaultOutput = "bin/spago-script-go"

-- | Puts the prelude, the Go packages and the scripts' Go module into the CLI's bundle, then
-- | builds the CLI, which embeds the bundle, to the output path.
buildSpagoScriptGo :: forall r. FilePath -> Om r () Unit
buildSpagoScriptGo output = do
  preludeManifest <- read "spago.yaml"
  removeDir bundle
  bundlePrelude preludeManifest
  for_ (goPackagesOf preludeManifest) (bundleGoPackage preludeManifest)
  write (bundle / "spago.yaml") (scriptsManifest preludeManifest)
  mkdirp (bundle / "out")
  write (bundle / "out" / "go.mod.template") scriptsGoModule
  buildCli
  log ("built " <> output)
  where
  bundlePrelude preludeManifest = do
    copyTree "src" (bundle / "prelude" / "src")
    write (bundle / "prelude" / "spago.yaml") (packageSection preludeManifest)

  bundleGoPackage preludeManifest name = do
    checkout <- packageCheckout preludeManifest name
    copyTree (checkout / "src") (bundle / "packages" / name / "src")
    manifest <- read (checkout / "spago.yaml")
    write (bundle / "packages" / name / "spago.yaml") (packageSection manifest)

  buildCli = do
    mkdirp (directoryOf output)
    _ <- xWith "go" [ "build", "-o", output, "." ] (_ { cwd = Just cli })
    pure unit

bundle :: FilePath
bundle = cli / "bundle"

cli :: FilePath
cli = "cmd" / "spago-script-go"

-- | The purescript-go packages the prelude depends on: go-io, go-os and the rest.
goPackagesOf :: String -> Array String
goPackagesOf = Array.filter isGoPackage <<< dependencies
  where
  isGoPackage name = String.take 3 name == "go-"

-- | Where a purescript-go package's sources are: in `PURESCRIPT_GO`'s checkout, or where Iris
-- | fetched the commit that spago.yaml pins.
packageCheckout :: forall r. String -> String -> Om r () FilePath
packageCheckout preludeManifest name = do
  localCheckout <- lookupEnv "PURESCRIPT_GO" # liftEffect
  case localCheckout, extraPackageRef name preludeManifest of
    Just checkout, _ -> pure (checkout / "packages" / name)
    Nothing, Just ref -> pure (".spago" / "p" / name / ref / "packages" / name)
    Nothing, Nothing -> throwError (error ("spago.yaml doesn't pin " <> name <> " to a commit")) # liftAff

-- | The manifest of the project scripts compile in: it depends on everything the prelude does,
-- | and on the prelude.
scriptsManifest :: String -> String
scriptsManifest preludeManifest = String.joinWith "\n"
  ( [ "package:", "  name: script", "  dependencies:" ]
      <> (("    - " <> _) <$> Array.sort (Array.nub (dependencies preludeManifest <> [ "spago-script-go" ])))
      <> [ "workspace:", "  packageSet:", "    registry: " <> fromMaybe "77.9.0" (registryVersion preludeManifest), "" ]
  )

-- | The Go module a script compiles into. It is a template because Go's embed leaves out
-- | directories with a go.mod.
scriptsGoModule :: String
scriptsGoModule = String.joinWith "\n"
  [ "module spago-script"
  , ""
  , "go 1.27.0"
  , ""
  , "require ("
  , "\tgithub.com/i-am-the-slime/iris-go " <> irisGoVersion
  , "\tmodernc.org/sqlite v1.62.0"
  , ")"
  , ""
  ]

-- | The iris-go runtime the Go that googoo writes needs.
irisGoVersion :: String
irisGoVersion = "v0.9.0"

directoryOf :: FilePath -> FilePath
directoryOf path = fromMaybe "." (String.lastIndexOf (Pattern "/") path <#> \at -> String.take at path)
