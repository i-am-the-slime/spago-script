module Script.Environment
  ( setEnv
  , unsetEnv
  , setEnvUnlessSet
  , envOr
  ) where

import Script.Prelude

import Data.Maybe (fromMaybe)
import Go.OS (EnvName(..), EnvValue(..))
import Go.OS as OS

-- | Sets a variable for this script and every program it starts from now on.
setEnv :: forall m. MonadEffect m => String -> String -> m Unit
setEnv name value = OS.setenv (EnvName name) (EnvValue value) # liftEffect

unsetEnv :: forall m. MonadEffect m => String -> m Unit
unsetEnv name = OS.unsetenv (EnvName name) # liftEffect

-- | Sets a variable to the value unless it is set already, as `export X=${X:-value}` does, and
-- | returns what it ends up as.
setEnvUnlessSet :: forall m. MonadEffect m => String -> String -> m String
setEnvUnlessSet name value = do
  existing <- lookupEnv name # liftEffect
  case existing of
    Just set -> pure set
    Nothing -> do
      setEnv name value
      pure value

-- | The variable's value, or the fallback when it isn't set.
envOr :: forall m. MonadEffect m => String -> String -> m String
envOr name fallback = fromMaybe fallback <$> (lookupEnv name # liftEffect)
