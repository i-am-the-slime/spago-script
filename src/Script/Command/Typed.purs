module Script.Command.Typed
  ( class TypedArgs
  , typedArgs
  , class GrammarCommand
  , grammarCommand
  , CommandInvocation(..)
  , typedCommand
  ) where

import Prim (Array, Constraint, String, Symbol, Type)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Script.Command.Grammar (Command, Grammar)
import Script.Command.Lex (class LexTemplate, class RenderTokens, renderTokens)
import Script.Command.Validate (class Validate)
import Type.Proxy (Proxy(..))


class TypedArgs :: Grammar -> Symbol -> Type -> Constraint
class TypedArgs grammar template input where
  typedArgs :: input -> Array String

instance
  ( LexTemplate template tokens
  , Validate grammar tokens input
  , RenderTokens tokens input
  ) =>
  TypedArgs grammar template input where
  typedArgs = renderTokens (Proxy :: Proxy tokens)

class GrammarCommand :: Grammar -> Constraint
class GrammarCommand grammar where
  grammarCommand :: Proxy grammar -> String

instance IsSymbol executable => GrammarCommand (Command executable options positionals subcommands) where
  grammarCommand _ = reflectSymbol (Proxy :: Proxy executable)

newtype CommandInvocation = CommandInvocation
  { executable :: String
  , arguments :: Array String
  }

typedCommand
  :: forall @grammar @template input
   . GrammarCommand grammar
  => TypedArgs grammar template input
  => input
  -> CommandInvocation
typedCommand input = CommandInvocation
  { executable: grammarCommand (Proxy :: Proxy grammar)
  , arguments: typedArgs @grammar @template input
  }
