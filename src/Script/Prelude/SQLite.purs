module Script.Prelude.SQLite
  ( SQLitePath(..)
  , SQLiteQuery(..)
  , querySQLiteText
  ) where

import Prelude

import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn2, runEffectFn2)
import Promise (Promise)
import Promise.Aff (toAffE)

newtype SQLitePath = SQLitePath String

newtype SQLiteQuery = SQLiteQuery String

querySQLiteText :: SQLitePath -> SQLiteQuery -> Aff String
querySQLiteText path query = toAffE $ runEffectFn2 querySQLiteTextImpl path query

foreign import querySQLiteTextImpl :: EffectFn2 SQLitePath SQLiteQuery (Promise String)
