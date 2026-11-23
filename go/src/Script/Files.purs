module Script.Files
  ( filesUnder
  , filesEndingWith
  , copyTree
  , readJSONFile
  , writeJSONFile
  , absolutePath
  , changeDirectory
  , scriptDirectory
  ) where

import Script.Prelude

import Data.Array as Array
import Data.Either (either)
import Data.Foldable (for_)
import Data.Newtype (un)
import Data.String (Pattern(..))
import Data.String as String
import Data.Traversable (for)
import Effect.Aff (throwError)
import Effect.Exception (error)
import Go.FilePath as Go
import Go.OS as OS
import Go.Path.Filepath as Filepath
import Yoga.JSON.Error (renderHumanError)

-- | Every file below the directory, however deep, sorted. Paths start with the directory.
filesUnder :: forall m. MonadAff m => FilePath -> m (Array FilePath)
filesUnder directory = do
  names <- listDir directory
  found <- for names (filesAt <<< (directory / _))
  pure (Array.sort (Array.concat found))
  where
  filesAt path = do
    isDirectory <- isDir path
    if isDirectory then filesUnder path else pure [ path ]

-- | The files below the directory whose names end with the suffix, such as `.go`.
filesEndingWith :: forall m. MonadAff m => String -> FilePath -> m (Array FilePath)
filesEndingWith suffix directory = Array.filter endsWithSuffix <$> filesUnder directory
  where
  endsWithSuffix path = String.stripSuffix (Pattern suffix) path /= Nothing

-- | Copies a directory and everything in it, as `cp -RL` does: links are copied as what they
-- | point at.
copyTree :: forall m. MonadAff m => FilePath -> FilePath -> m Unit
copyTree from to = do
  mkdirp to
  names <- listDir from
  for_ names \name -> do
    isDirectory <- isDir (from / name)
    if isDirectory then copyTree (from / name) (to / name) else copyFile (from / name) (to / name)

-- | Reads a JSON file into a value, failing with the path and what didn't fit.
readJSONFile :: forall m @a. MonadAff m => ReadForeign a => FilePath -> m a
readJSONFile path = do
  json <- readTextFile path
  case readJSON json of
    Right value -> pure value
    Left errors -> throwError (error (path <> ": " <> describe errors)) # liftAff
  where
  describe errors = String.joinWith "; " (renderHumanError <$> Array.fromFoldable errors)

-- | Writes a value as JSON, indented by two spaces, with a final newline.
writeJSONFile :: forall m a. MonadAff m => WriteForeign a => FilePath -> a -> m Unit
writeJSONFile path value = write path (writePrettyJSON 2 value <> "\n")

-- | Makes the directory the current one, for the script and the programs it starts, as `cd` does.
changeDirectory :: forall m. MonadAff m => FilePath -> m Unit
changeDirectory path = do
  changed <- OS.chdir (Go.FilePath path) # liftEffect
  either (\_ -> throwError (error ("can't change to " <> path)) # liftAff) pure changed

-- | The directory the running script is in, as `$(dirname "$0")`, made absolute; the current
-- | directory when the script wasn't started by spago-script-go.
scriptDirectory :: forall m. MonadEffect m => m FilePath
scriptDirectory = do
  script <- lookupEnv "SPAGO_SCRIPT_PATH" # liftEffect
  case script of
    Just path -> pure (un Go.FilePath (Filepath.dir (Go.FilePath path)))
    Nothing -> cwd # liftEffect

-- | The path made absolute against the current directory.
absolutePath :: forall m. MonadEffect m => FilePath -> m FilePath
absolutePath path = do
  absolute <- Filepath.abs (Go.FilePath path) # liftEffect
  pure (either (const path) (un Go.FilePath) absolute)
