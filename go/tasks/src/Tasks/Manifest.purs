-- | Just enough of a spago.yaml for building spago-script-go: the lines are read as Spago writes
-- | them, two blanks per level, not as YAML in general.
module Tasks.Manifest
  ( packageSection
  , dependencies
  , registryVersion
  , extraPackageRef
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..))
import Data.String as String
import Script.Text (linesOf)

-- | The `package:` part of a manifest without its `test:` section and without the workspace, as
-- | a package inside another workspace needs it.
packageSection :: String -> String
packageSection manifest = String.joinWith "\n" (withoutTestSection packageLines) <> "\n"
  where
  packageLines = Array.takeWhile (not <<< startsWith "workspace:") (linesOf manifest)

  withoutTestSection lines = case Array.findIndex (_ == "  test:") lines of
    Nothing -> lines
    Just start -> Array.take start lines <> Array.dropWhile (startsWith "    ") (Array.drop (start + 1) lines)

-- | The names under the package's `dependencies:`, without version ranges.
dependencies :: String -> Array String
dependencies manifest = nameOf <$> Array.takeWhile (startsWith "    - ") afterHeading
  where
  afterHeading = Array.drop 1 (Array.dropWhile (_ /= "  dependencies:") (linesOf manifest))
  nameOf line = String.trim (fromMaybe "" (Array.head (String.split (Pattern ":") (String.drop 6 line))))

-- | The package set's registry version.
registryVersion :: String -> Maybe String
registryVersion manifest = String.trim <$> Array.findMap (String.stripPrefix (Pattern "    registry:")) (linesOf manifest)

-- | The git ref an extra package is pinned to.
extraPackageRef :: String -> String -> Maybe String
extraPackageRef name manifest = String.trim <$> Array.findMap (String.stripPrefix (Pattern "      ref:")) packageLines
  where
  packageLines = Array.takeWhile (startsWith "      ") (Array.drop 1 (Array.dropWhile (_ /= "    " <> name <> ":") (linesOf manifest)))

startsWith :: String -> String -> Boolean
startsWith prefix line = String.take (String.length prefix) line == prefix
