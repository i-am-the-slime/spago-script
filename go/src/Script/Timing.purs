module Script.Timing
  ( timed
  , timedRuns
  ) where

import Script.Prelude

import Data.Array as Array
import Data.DateTime.Instant (unInstant)
import Data.Foldable (for_)
import Data.Traversable (for)
import Data.Newtype (un)
import Data.Time.Duration (Milliseconds(..))
import Effect.Now (now)

-- | Runs the action and says how many seconds it took.
timed :: forall m a. MonadEffect m => m a -> m { result :: a, seconds :: Number }
timed action = do
  started <- millisecondsNow
  result <- action
  finished <- millisecondsNow
  pure { result, seconds: div (finished - started) 1000.0 }
  where
  millisecondsNow = un Milliseconds <<< unInstant <$> (now # liftEffect)

-- | Runs the action `warmups` times without counting, then `runs` times, and returns how many
-- | seconds each counted run took. A program in-process stand-in for `hyperfine`.
timedRuns :: forall m a. MonadEffect m => { warmups :: Int, runs :: Int } -> m a -> m (Array Number)
timedRuns { warmups, runs } action = do
  for_ (Array.replicate warmups unit) \_ -> action
  for (Array.replicate runs unit) \_ -> _.seconds <$> timed action
