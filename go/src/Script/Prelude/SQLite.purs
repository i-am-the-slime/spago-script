module Script.Prelude.SQLite
  ( SQLitePath(..)
  , SQLiteQuery(..)
  , querySQLiteText
  ) where

import Prelude

import Data.Either (Either(..), either)
import Data.Newtype (class Newtype, un)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Go.IO (IO)

newtype SQLitePath = SQLitePath String

derive instance Newtype SQLitePath _

newtype SQLiteQuery = SQLiteQuery String

derive instance Newtype SQLiteQuery _

-- | Runs a query that returns one row with one text column, and returns that text. The database is
-- | opened read-only, except for `:memory:`.
querySQLiteText :: SQLitePath -> SQLiteQuery -> Aff String
querySQLiteText path query = do
  answer <- makeAff \resolve -> querySQLiteTextImpl Left Right (un SQLitePath path) (un SQLiteQuery query) (resumeWith resolve) $> nonCanceler
  either (throwError <<< error) pure answer
  where
  resumeWith resolve answer = resolve (Right answer) # liftEffect

foreign import querySQLiteTextImpl
  :: forall r. (String -> r) -> (String -> r) -> String -> String -> (r -> IO Unit) -> Effect Unit
