module Script.Command.Lex
  ( Piece
  , Literal
  , Hole
  , Pieces
  , NilPieces
  , SnocPiece
  , Token
  , Word
  , Tokens
  , NilTokens
  , SnocToken
  , class LexTemplate
  , lexTemplate
  , QuoteMode
  , Bare
  , SingleQuoted
  , DoubleQuoted
  , class LexScan
  , class LexChar
  , class LexEscape
  , class LexAfterDollar
  , class LexAfterDollarHead
  , class ParseSimpleStart
  , class ParseSimpleVariable
  , class ParseSimpleDispatch
  , class ParseBracedSegment
  , class ParseBracedSegmentDispatch
  , class ParseBracedRest
  , class ParseBracedRestHead
  , class ParseBracedRestDispatch
  , class FlushLiteral
  , class AddHole
  , class FlushToken
  , class IsVariableChar
  , class RenderTokens
  , renderTokens
  , class RenderTokenList
  , renderTokenList
  , class RenderToken
  , renderToken
  , class RenderPieces
  , renderPieces
  , class RenderPiece
  , renderPiece
  , class ResolvePath
  , resolvePath
  , class SplitPath
  , class ResolvePathPart
  , resolvePathPart
  ) where

import Prelude ((<>))

import Data.Array as Array
import Data.Symbol (class IsSymbol, reflectSymbol)
import Prim (Array, Boolean, Constraint, Record, Row, String, Symbol, Type)
import Prim.Boolean (False, True)
import Prim.Row as Row
import Prim.Symbol as Symbol
import Prim.TypeError (class Fail, Text)
import Record as Record
import Type.Proxy (Proxy(..))
import Yoga.Format.Interpolate (class Interpolate, interpolate)


data Piece
foreign import data Literal :: Symbol -> Piece
foreign import data Hole :: Symbol -> Piece

data Pieces
foreign import data NilPieces :: Pieces
foreign import data SnocPiece :: Pieces -> Piece -> Pieces

data Token
foreign import data Word :: Pieces -> Token

data Tokens
foreign import data NilTokens :: Tokens
foreign import data SnocToken :: Tokens -> Token -> Tokens

-- | Lex a template into argv tokens. The functional dependency makes the AST
-- | available to later compile-time consumers without running the renderer.
class LexTemplate :: Symbol -> Tokens -> Constraint
class LexTemplate template tokens | template -> tokens where
  lexTemplate :: Proxy template -> Proxy tokens

instance
  LexScan Bare template NilTokens NilPieces "" False tokens =>
  LexTemplate template tokens where
  lexTemplate _ = Proxy

-- Internal quote modes.
data QuoteMode
foreign import data Bare :: QuoteMode
foreign import data SingleQuoted :: QuoteMode
foreign import data DoubleQuoted :: QuoteMode

class LexScan :: QuoteMode -> Symbol -> Tokens -> Pieces -> Symbol -> Boolean -> Tokens -> Constraint
class LexScan mode input tokens pieces literal active result
  | mode input tokens pieces literal active -> result

instance
  FlushToken active tokens pieces literal result =>
  LexScan Bare "" tokens pieces literal active result
else instance
  Fail (Text "Command template has an unmatched single quote") =>
  LexScan SingleQuoted "" tokens pieces literal active result
else instance
  Fail (Text "Command template has an unmatched double quote") =>
  LexScan DoubleQuoted "" tokens pieces literal active result
else instance
  ( Symbol.Cons head tail input
  , LexChar mode head tail tokens pieces literal active result
  ) =>
  LexScan mode input tokens pieces literal active result

class LexChar :: QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Boolean -> Tokens -> Constraint
class LexChar mode head tail tokens pieces literal active result
  | mode head tail tokens pieces literal active -> result

-- Unquoted separators terminate an argv element.
instance
  ( FlushToken active tokens pieces literal tokens'
  , LexScan Bare tail tokens' NilPieces "" False result
  ) =>
  LexChar Bare " " tail tokens pieces literal active result
else instance
  ( FlushToken active tokens pieces literal tokens'
  , LexScan Bare tail tokens' NilPieces "" False result
  ) =>
  LexChar Bare "\t" tail tokens pieces literal active result
else instance
  ( FlushToken active tokens pieces literal tokens'
  , LexScan Bare tail tokens' NilPieces "" False result
  ) =>
  LexChar Bare "\n" tail tokens pieces literal active result
else instance
  ( FlushToken active tokens pieces literal tokens'
  , LexScan Bare tail tokens' NilPieces "" False result
  ) =>
  LexChar Bare "\r" tail tokens pieces literal active result
-- Quotes are syntax, but opening even an empty quote starts a token.
else instance
  LexScan SingleQuoted tail tokens pieces literal True result =>
  LexChar Bare "'" tail tokens pieces literal active result
else instance
  LexScan DoubleQuoted tail tokens pieces literal True result =>
  LexChar Bare "\"" tail tokens pieces literal active result
else instance
  LexEscape Bare tail tokens pieces literal result =>
  LexChar Bare "\\" tail tokens pieces literal active result
else instance
  LexAfterDollar Bare tail tokens pieces literal result =>
  LexChar Bare "$" tail tokens pieces literal active result
-- Single quotes preserve everything except their closing quote.
else instance
  LexScan Bare tail tokens pieces literal True result =>
  LexChar SingleQuoted "'" tail tokens pieces literal active result
else instance
  ( Symbol.Append literal head literal'
  , LexScan SingleQuoted tail tokens pieces literal' True result
  ) =>
  LexChar SingleQuoted head tail tokens pieces literal active result
-- Double quotes preserve separators and single quotes, while retaining
-- interpolation and backslash escaping.
else instance
  LexScan Bare tail tokens pieces literal True result =>
  LexChar DoubleQuoted "\"" tail tokens pieces literal active result
else instance
  LexEscape DoubleQuoted tail tokens pieces literal result =>
  LexChar DoubleQuoted "\\" tail tokens pieces literal active result
else instance
  LexAfterDollar DoubleQuoted tail tokens pieces literal result =>
  LexChar DoubleQuoted "$" tail tokens pieces literal active result
else instance
  ( Symbol.Append literal head literal'
  , LexScan DoubleQuoted tail tokens pieces literal' True result
  ) =>
  LexChar DoubleQuoted head tail tokens pieces literal active result
-- Remaining bare characters are literal text.
else instance
  ( Symbol.Append literal head literal'
  , LexScan Bare tail tokens pieces literal' True result
  ) =>
  LexChar Bare head tail tokens pieces literal active result

class LexEscape :: QuoteMode -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class LexEscape mode input tokens pieces literal result
  | mode input tokens pieces literal -> result

instance
  Fail (Text "Command template ends with a trailing escape") =>
  LexEscape mode "" tokens pieces literal result
else instance
  ( Symbol.Cons escaped tail input
  , Symbol.Append literal escaped literal'
  , LexScan mode tail tokens pieces literal' True result
  ) =>
  LexEscape mode input tokens pieces literal result

class LexAfterDollar :: QuoteMode -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class LexAfterDollar mode input tokens pieces literal result
  | mode input tokens pieces literal -> result

instance
  Fail (Text "Command template contains an empty variable after $") =>
  LexAfterDollar mode "" tokens pieces literal result
else instance
  ( Symbol.Cons head tail input
  , LexAfterDollarHead head mode tail tokens pieces literal result
  ) =>
  LexAfterDollar mode input tokens pieces literal result

class LexAfterDollarHead :: Symbol -> QuoteMode -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class LexAfterDollarHead head mode tail tokens pieces literal result
  | head mode tail tokens pieces literal -> result

instance
  ParseBracedSegment mode tail "" tokens pieces literal result =>
  LexAfterDollarHead "{" mode tail tokens pieces literal result
else instance
  ( IsVariableChar head valid
  , ParseSimpleStart valid mode head tail tokens pieces literal result
  ) =>
  LexAfterDollarHead head mode tail tokens pieces literal result

class ParseSimpleStart :: Boolean -> QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseSimpleStart valid mode head tail tokens pieces literal result
  | valid mode head tail tokens pieces literal -> result

instance
  ( Symbol.Append "" head name
  , ParseSimpleVariable mode tail name tokens pieces literal result
  ) =>
  ParseSimpleStart True mode head tail tokens pieces literal result
else instance
  Fail (Text "Command template contains an empty variable after $") =>
  ParseSimpleStart False mode head tail tokens pieces literal result

class ParseSimpleVariable :: QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseSimpleVariable mode input name tokens pieces literal result
  | mode input name tokens pieces literal -> result

instance
  ( AddHole literal pieces name pieces'
  , LexScan mode "" tokens pieces' "" True result
  ) =>
  ParseSimpleVariable mode "" name tokens pieces literal result
else instance
  ( Symbol.Cons head tail input
  , IsVariableChar head valid
  , ParseSimpleDispatch valid mode input head tail name tokens pieces literal result
  ) =>
  ParseSimpleVariable mode input name tokens pieces literal result

class ParseSimpleDispatch :: Boolean -> QuoteMode -> Symbol -> Symbol -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseSimpleDispatch valid mode input head tail name tokens pieces literal result
  | valid mode input head tail name tokens pieces literal -> result

instance
  ( Symbol.Append name head name'
  , ParseSimpleVariable mode tail name' tokens pieces literal result
  ) =>
  ParseSimpleDispatch True mode input head tail name tokens pieces literal result
else instance
  ( AddHole literal pieces name pieces'
  , LexScan mode input tokens pieces' "" True result
  ) =>
  ParseSimpleDispatch False mode input head tail name tokens pieces literal result

-- A braced path consists of non-empty identifier segments separated by dots.
class ParseBracedSegment :: QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseBracedSegment mode input path tokens pieces literal result
  | mode input path tokens pieces literal -> result

instance
  Fail (Text "Command template contains an unterminated braced variable") =>
  ParseBracedSegment mode "" path tokens pieces literal result
else instance
  ( Symbol.Cons head tail input
  , IsVariableChar head valid
  , ParseBracedSegmentDispatch valid mode head tail path tokens pieces literal result
  ) =>
  ParseBracedSegment mode input path tokens pieces literal result

class ParseBracedSegmentDispatch :: Boolean -> QuoteMode -> Symbol -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseBracedSegmentDispatch valid mode head tail path tokens pieces literal result
  | valid mode head tail path tokens pieces literal -> result

instance
  ( Symbol.Append path head path'
  , ParseBracedRest mode tail path' tokens pieces literal result
  ) =>
  ParseBracedSegmentDispatch True mode head tail path tokens pieces literal result
else instance
  Fail (Text "Command template contains an empty or malformed braced variable") =>
  ParseBracedSegmentDispatch False mode head tail path tokens pieces literal result

class ParseBracedRest :: QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseBracedRest mode input path tokens pieces literal result
  | mode input path tokens pieces literal -> result

instance
  Fail (Text "Command template contains an unterminated braced variable") =>
  ParseBracedRest mode "" path tokens pieces literal result
else instance
  ( Symbol.Cons head tail input
  , ParseBracedRestHead head mode tail path tokens pieces literal result
  ) =>
  ParseBracedRest mode input path tokens pieces literal result

class ParseBracedRestHead :: Symbol -> QuoteMode -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseBracedRestHead head mode tail path tokens pieces literal result
  | head mode tail path tokens pieces literal -> result

instance
  ( AddHole literal pieces path pieces'
  , LexScan mode tail tokens pieces' "" True result
  ) =>
  ParseBracedRestHead "}" mode tail path tokens pieces literal result
else instance
  ( Symbol.Append path "." path'
  , ParseBracedSegment mode tail path' tokens pieces literal result
  ) =>
  ParseBracedRestHead "." mode tail path tokens pieces literal result
else instance
  ( IsVariableChar head valid
  , ParseBracedRestDispatch valid mode head tail path tokens pieces literal result
  ) =>
  ParseBracedRestHead head mode tail path tokens pieces literal result

class ParseBracedRestDispatch :: Boolean -> QuoteMode -> Symbol -> Symbol -> Symbol -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class ParseBracedRestDispatch valid mode head tail path tokens pieces literal result
  | valid mode head tail path tokens pieces literal -> result

instance
  ( Symbol.Append path head path'
  , ParseBracedRest mode tail path' tokens pieces literal result
  ) =>
  ParseBracedRestDispatch True mode head tail path tokens pieces literal result
else instance
  Fail (Text "Command template contains a malformed braced variable") =>
  ParseBracedRestDispatch False mode head tail path tokens pieces literal result

class FlushLiteral :: Symbol -> Pieces -> Pieces -> Constraint
class FlushLiteral literal pieces result | literal pieces -> result

instance FlushLiteral "" pieces pieces
else instance FlushLiteral literal pieces (SnocPiece pieces (Literal literal))

class AddHole :: Symbol -> Pieces -> Symbol -> Pieces -> Constraint
class AddHole literal pieces path result | literal pieces path -> result

instance
  FlushLiteral literal pieces pieces' =>
  AddHole literal pieces path (SnocPiece pieces' (Hole path))

class FlushToken :: Boolean -> Tokens -> Pieces -> Symbol -> Tokens -> Constraint
class FlushToken active tokens pieces literal result
  | active tokens pieces literal -> result

instance FlushToken False tokens pieces literal tokens
else instance
  FlushLiteral literal pieces pieces' =>
  FlushToken True tokens pieces literal (SnocToken tokens (Word pieces'))

class IsVariableChar :: Symbol -> Boolean -> Constraint
class IsVariableChar char valid | char -> valid

instance IsVariableChar "a" True
else instance IsVariableChar "b" True
else instance IsVariableChar "c" True
else instance IsVariableChar "d" True
else instance IsVariableChar "e" True
else instance IsVariableChar "f" True
else instance IsVariableChar "g" True
else instance IsVariableChar "h" True
else instance IsVariableChar "i" True
else instance IsVariableChar "j" True
else instance IsVariableChar "k" True
else instance IsVariableChar "l" True
else instance IsVariableChar "m" True
else instance IsVariableChar "n" True
else instance IsVariableChar "o" True
else instance IsVariableChar "p" True
else instance IsVariableChar "q" True
else instance IsVariableChar "r" True
else instance IsVariableChar "s" True
else instance IsVariableChar "t" True
else instance IsVariableChar "u" True
else instance IsVariableChar "v" True
else instance IsVariableChar "w" True
else instance IsVariableChar "x" True
else instance IsVariableChar "y" True
else instance IsVariableChar "z" True
else instance IsVariableChar "A" True
else instance IsVariableChar "B" True
else instance IsVariableChar "C" True
else instance IsVariableChar "D" True
else instance IsVariableChar "E" True
else instance IsVariableChar "F" True
else instance IsVariableChar "G" True
else instance IsVariableChar "H" True
else instance IsVariableChar "I" True
else instance IsVariableChar "J" True
else instance IsVariableChar "K" True
else instance IsVariableChar "L" True
else instance IsVariableChar "M" True
else instance IsVariableChar "N" True
else instance IsVariableChar "O" True
else instance IsVariableChar "P" True
else instance IsVariableChar "Q" True
else instance IsVariableChar "R" True
else instance IsVariableChar "S" True
else instance IsVariableChar "T" True
else instance IsVariableChar "U" True
else instance IsVariableChar "V" True
else instance IsVariableChar "W" True
else instance IsVariableChar "X" True
else instance IsVariableChar "Y" True
else instance IsVariableChar "Z" True
else instance IsVariableChar "0" True
else instance IsVariableChar "1" True
else instance IsVariableChar "2" True
else instance IsVariableChar "3" True
else instance IsVariableChar "4" True
else instance IsVariableChar "5" True
else instance IsVariableChar "6" True
else instance IsVariableChar "7" True
else instance IsVariableChar "8" True
else instance IsVariableChar "9" True
else instance IsVariableChar "_" True
else instance IsVariableChar char False

-- | Render the token AST directly. Each Word produces exactly one array entry;
-- | literal and hole pieces are concatenated only within that entry.
class RenderTokens :: Tokens -> Type -> Constraint
class RenderTokens tokens input where
  renderTokens :: Proxy tokens -> input -> Array String

instance RenderTokenList tokens row => RenderTokens tokens (Record row) where
  renderTokens proxy record = renderTokenList proxy record []

class RenderTokenList :: Tokens -> Row Type -> Constraint
class RenderTokenList tokens row where
  renderTokenList :: Proxy tokens -> Record row -> Array String -> Array String

instance RenderTokenList NilTokens row where
  renderTokenList _ _ suffix = suffix

instance
  ( RenderTokenList initial row
  , RenderToken token row
  ) =>
  RenderTokenList (SnocToken initial token) row where
  renderTokenList _ record suffix =
    renderTokenList
      (Proxy :: Proxy initial)
      record
      (Array.cons (renderToken (Proxy :: Proxy token) record) suffix)

class RenderToken :: Token -> Row Type -> Constraint
class RenderToken token row where
  renderToken :: Proxy token -> Record row -> String

instance RenderPieces pieces row => RenderToken (Word pieces) row where
  renderToken _ record = renderPieces (Proxy :: Proxy pieces) record ""

class RenderPieces :: Pieces -> Row Type -> Constraint
class RenderPieces pieces row where
  renderPieces :: Proxy pieces -> Record row -> String -> String

instance RenderPieces NilPieces row where
  renderPieces _ _ suffix = suffix

instance
  ( RenderPieces initial row
  , RenderPiece piece row
  ) =>
  RenderPieces (SnocPiece initial piece) row where
  renderPieces _ record suffix =
    renderPieces
      (Proxy :: Proxy initial)
      record
      (renderPiece (Proxy :: Proxy piece) record <> suffix)

class RenderPiece :: Piece -> Row Type -> Constraint
class RenderPiece piece row where
  renderPiece :: Proxy piece -> Record row -> String

instance IsSymbol literal => RenderPiece (Literal literal) row where
  renderPiece _ _ = reflectSymbol (Proxy :: Proxy literal)

instance ResolvePath path row => RenderPiece (Hole path) row where
  renderPiece _ record = resolvePath (Proxy :: Proxy path) record

class ResolvePath :: Symbol -> Row Type -> Constraint
class ResolvePath path row where
  resolvePath :: Proxy path -> Record row -> String

instance
  ( Symbol.Cons head tail path
  , SplitPath head tail "" hasDot field rest
  , ResolvePathPart hasDot field rest row
  ) =>
  ResolvePath path row where
  resolvePath _ =
    resolvePathPart
      (Proxy :: Proxy hasDot)
      (Proxy :: Proxy field)
      (Proxy :: Proxy rest)

class SplitPath :: Symbol -> Symbol -> Symbol -> Boolean -> Symbol -> Symbol -> Constraint
class SplitPath head tail accumulated hasDot field rest
  | head tail accumulated -> hasDot field rest

instance SplitPath "." tail accumulated True accumulated tail
else instance
  Symbol.Append accumulated head field =>
  SplitPath head "" accumulated False field ""
else instance
  ( Symbol.Append accumulated head accumulated'
  , Symbol.Cons next rest' tail
  , SplitPath next rest' accumulated' hasDot field rest
  ) =>
  SplitPath head tail accumulated hasDot field rest

class ResolvePathPart :: Boolean -> Symbol -> Symbol -> Row Type -> Constraint
class ResolvePathPart hasDot field rest row where
  resolvePathPart :: Proxy hasDot -> Proxy field -> Proxy rest -> Record row -> String

instance
  ( IsSymbol field
  , Row.Cons field value tail row
  , Interpolate value
  ) =>
  ResolvePathPart False field rest row where
  resolvePathPart _ _ _ record =
    interpolate (Record.get (Proxy :: Proxy field) record)

instance
  ( IsSymbol field
  , Row.Cons field (Record nested) tail row
  , ResolvePath rest nested
  ) =>
  ResolvePathPart True field rest row where
  resolvePathPart _ _ _ record = do
    let nested = Record.get (Proxy :: Proxy field) record
    resolvePath (Proxy :: Proxy rest) nested
