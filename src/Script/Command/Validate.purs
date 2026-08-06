module Script.Command.Validate where

import Prim (Boolean, Char, Constraint, Int, Number, Record, Row, String, Symbol, Type)
import Prim.Boolean (False, True)
import Prim.Row as Row
import Prim.Symbol as Symbol
import Prim.TypeError (Beside, Text, class Fail)
import Script.Command.Grammar
  ( AddOption
  , AddPositional
  , AddSubcommand
  , BooleanValue
  , CharValue
  , Cardinality
  , Command
  , Grammar
  , IntValue
  , Many
  , Name
  , Names
  , NoNames
  , NoOperand
  , NoOptions
  , NoPositionals
  , NoSubcommands
  , NumberValue
  , Once
  , Operand
  , One
  , Optional
  , Options
  , Positionals
  , Repeat
  , Repeatable
  , RequiredOperand
  , Some
  , Subcommands
  , TextValue
  , ValueKind
  )
import Script.Command.Lex
  ( Hole
  , Literal
  , NilPieces
  , NilTokens
  , Piece
  , Pieces
  , SnocPiece
  , SnocToken
  , Token
  , Tokens
  , Word
  )


-- | Proves that a lexed command template is accepted by a grammar and that
-- | every interpolation has the exact semantic type required at its argv
-- | position. The input type is the same `Record row` consumed by RenderTokens.
class Validate :: Grammar -> Tokens -> Type -> Constraint
class Validate grammar tokens input

instance
  ( ReverseTokens tokens TNil argv
  , ValidateRoot grammar argv row
  ) =>
  Validate grammar tokens (Record row)

-- Forward list used internally because the lexer deliberately exposes a snoc
-- list, while command parsing must consume argv from left to right.
data TokenList
foreign import data TNil :: TokenList
foreign import data TCons :: Token -> TokenList -> TokenList

class ReverseTokens :: Tokens -> TokenList -> TokenList -> Constraint
class ReverseTokens tokens accumulated result | tokens accumulated -> result

instance ReverseTokens NilTokens accumulated accumulated
else instance
  ReverseTokens prefix (TCons token accumulated) result =>
  ReverseTokens (SnocToken prefix token) accumulated result

class ValidateRoot :: Grammar -> TokenList -> Row Type -> Constraint
class ValidateRoot grammar argv input

instance
  Scan command options positionals subcommands NoSeen False argv TNil input =>
  ValidateRoot (Command command options positionals subcommands) argv input

-- Set of option declarations already consumed under Once semantics.
data Seen
foreign import data NoSeen :: Seen
foreign import data SeenOption :: Names -> Seen -> Seen

class SeenContains :: Names -> Seen -> Boolean -> Constraint
class SeenContains names seen result | names seen -> result

instance SeenContains names NoSeen False
else instance SeenContains names (SeenOption names rest) True
else instance SeenContains names rest result => SeenContains names (SeenOption other rest) result

class MarkOption :: Symbol -> Symbol -> Names -> Repeat -> Seen -> Seen -> Constraint
class MarkOption command option names repeat seen result
  | command option names repeat seen -> result

instance MarkOption command option names Repeatable seen seen
else instance
  ( SeenContains names seen duplicate
  , MarkOnce duplicate command option names seen result
  ) =>
  MarkOption command option names Once seen result

class MarkOnce :: Boolean -> Symbol -> Symbol -> Names -> Seen -> Seen -> Constraint
class MarkOnce duplicate command option names seen result
  | duplicate command option names seen -> result

instance MarkOnce False command option names seen (SeenOption names seen)
else instance
  Fail
    ( Beside
        (Beside (Beside (Text "Duplicate ") (Text command)) (Text " option: "))
        (Text option)
    ) =>
  MarkOnce True command option names seen result

-- Scan options first, retaining non-option words for positional matching. A
-- literal subcommand changes the active grammar immediately, so its options
-- are interpreted by that subcommand rather than by its parent.
class Scan
  :: Symbol
  -> Options
  -> Positionals
  -> Subcommands
  -> Seen
  -> Boolean
  -> TokenList
  -> TokenList
  -> Row Type
  -> Constraint
class Scan command options positionals subcommands seen afterDoubleDash argv positionalRev input

instance
  ( ReverseList positionalRev TNil positionalArgv
  , PositionalsUsage positionals usage
  , MatchPositionals command usage positionals positionals positionalArgv input
  ) =>
  Scan command options positionals NoSubcommands seen afterDoubleDash TNil positionalRev input
else instance
  Fail (Beside (Text command) (Text " expects a subcommand")) =>
  Scan command options positionals subcommands seen afterDoubleDash TNil positionalRev input
else instance
  Scan command options positionals subcommands seen True rest (TCons token positionalRev) input =>
  Scan command options positionals subcommands seen True (TCons token rest) positionalRev input
else instance
  Scan command options positionals subcommands seen True rest positionalRev input =>
  Scan
    command
    options
    positionals
    subcommands
    seen
    False
    (TCons (Word (SnocPiece NilPieces (Literal "--"))) rest)
    positionalRev
    input
else instance
  ( IsOptionSymbol symbol isOption
  , ScanLiteral isOption command options positionals subcommands seen symbol rest positionalRev input
  ) =>
  Scan
    command
    options
    positionals
    subcommands
    seen
    False
    (TCons (Word (SnocPiece NilPieces (Literal symbol))) rest)
    positionalRev
    input
else instance
  ScanNonOption command options positionals subcommands seen token rest positionalRev input =>
  Scan command options positionals subcommands seen False (TCons token rest) positionalRev input

class IsOptionSymbol :: Symbol -> Boolean -> Constraint
class IsOptionSymbol symbol result | symbol -> result

instance IsOptionSymbol "" False
else instance
  ( Symbol.Cons head tail symbol
  , IsHyphenStart head tail result
  ) =>
  IsOptionSymbol symbol result

class IsHyphenStart :: Symbol -> Symbol -> Boolean -> Constraint
class IsHyphenStart head tail result | head tail -> result

instance IsHyphenStart "-" "" False
else instance IsHyphenStart "-" "-" False
else instance IsHyphenStart "-" tail True
else instance IsHyphenStart head tail False

class ScanLiteral
  :: Boolean
  -> Symbol
  -> Options
  -> Positionals
  -> Subcommands
  -> Seen
  -> Symbol
  -> TokenList
  -> TokenList
  -> Row Type
  -> Constraint
class ScanLiteral isOption command options positionals subcommands seen symbol rest positionalRev input

instance
  ScanOption command options positionals subcommands seen symbol rest positionalRev input =>
  ScanLiteral True command options positionals subcommands seen symbol rest positionalRev input
else instance
  ScanNonOption
    command
    options
    positionals
    subcommands
    seen
    (Word (SnocPiece NilPieces (Literal symbol)))
    rest
    positionalRev
    input =>
  ScanLiteral False command options positionals subcommands seen symbol rest positionalRev input

class ScanOption
  :: Symbol
  -> Options
  -> Positionals
  -> Subcommands
  -> Seen
  -> Symbol
  -> TokenList
  -> TokenList
  -> Row Type
  -> Constraint
class ScanOption command options positionals subcommands seen option rest positionalRev input

instance
  ( FindOption command option options names operand repeat
  , MarkOption command option names repeat seen seen'
  , ConsumeOption command option operand rest remaining input
  , Scan command options positionals subcommands seen' False remaining positionalRev input
  ) =>
  ScanOption command options positionals subcommands seen option rest positionalRev input

class FindOption :: Symbol -> Symbol -> Options -> Names -> Operand -> Repeat -> Constraint
class FindOption command option options names operand repeat
  | command option options -> names operand repeat

instance
  Fail
    ( Beside
        (Beside (Beside (Text "Unknown ") (Text command)) (Text " option: "))
        (Text option)
    ) =>
  FindOption command option NoOptions names operand repeat
else instance
  ( HasName option names matches
  , FindOptionStep matches command option names operand repeat rest foundNames foundOperand foundRepeat
  ) =>
  FindOption
    command
    option
    (AddOption names operand repeat rest)
    foundNames
    foundOperand
    foundRepeat

class HasName :: Symbol -> Names -> Boolean -> Constraint
class HasName option names result | option names -> result

instance HasName option NoNames False
else instance HasName option (Name option rest) True
else instance HasName option rest result => HasName option (Name other rest) result

class FindOptionStep
  :: Boolean
  -> Symbol
  -> Symbol
  -> Names
  -> Operand
  -> Repeat
  -> Options
  -> Names
  -> Operand
  -> Repeat
  -> Constraint
class FindOptionStep matches command option names operand repeat rest foundNames foundOperand foundRepeat
  | matches command option names operand repeat rest -> foundNames foundOperand foundRepeat

instance FindOptionStep True command option names operand repeat rest names operand repeat
else instance
  FindOption command option rest foundNames foundOperand foundRepeat =>
  FindOptionStep False command option names operand repeat rest foundNames foundOperand foundRepeat

class ConsumeOption
  :: Symbol -> Symbol -> Operand -> TokenList -> TokenList -> Row Type -> Constraint
class ConsumeOption command option operand argv remaining input
  | command option operand argv input -> remaining

instance ConsumeOption command option NoOperand argv argv input
else instance
  ( CheckToken command context kind token input
  , Symbol.Append "option " option context
  ) =>
  ConsumeOption command option (RequiredOperand kind) (TCons token rest) rest input
else instance
  Fail
    ( Beside
        (Beside (Beside (Text command) (Text " option ")) (Text option))
        (Text " requires an operand")
    ) =>
  ConsumeOption command option (RequiredOperand kind) TNil remaining input

class ScanNonOption
  :: Symbol
  -> Options
  -> Positionals
  -> Subcommands
  -> Seen
  -> Token
  -> TokenList
  -> TokenList
  -> Row Type
  -> Constraint
class ScanNonOption command options positionals subcommands seen token rest positionalRev input

instance
  Scan command options positionals NoSubcommands seen False rest (TCons token positionalRev) input =>
  ScanNonOption command options positionals NoSubcommands seen token rest positionalRev input
else instance
  SelectSubcommand command token subcommands child rest input =>
  ScanNonOption command options positionals subcommands seen token rest positionalRev input

class SelectSubcommand
  :: Symbol -> Token -> Subcommands -> Grammar -> TokenList -> Row Type -> Constraint
class SelectSubcommand parent token subcommands child rest input

instance
  ( FindSubcommand parent name subcommands child
  , ValidateChild child rest input
  ) =>
  SelectSubcommand
    parent
    (Word (SnocPiece NilPieces (Literal name)))
    subcommands
    child
    rest
    input
else instance
  Fail (Beside (Text parent) (Text " expects a literal subcommand")) =>
  SelectSubcommand parent token subcommands child rest input

class FindSubcommand :: Symbol -> Symbol -> Subcommands -> Grammar -> Constraint
class FindSubcommand parent name subcommands child | parent name subcommands -> child

instance
  Fail
    ( Beside
        (Beside (Beside (Text "Unknown ") (Text parent)) (Text " subcommand: "))
        (Text name)
    ) =>
  FindSubcommand parent name NoSubcommands child
else instance FindSubcommand parent name (AddSubcommand name child rest) child
else instance
  FindSubcommand parent name rest child =>
  FindSubcommand parent name (AddSubcommand other grammar rest) child

class ValidateChild :: Grammar -> TokenList -> Row Type -> Constraint
class ValidateChild grammar rest input

instance
  Scan command options positionals subcommands NoSeen False rest TNil input =>
  ValidateChild (Command command options positionals subcommands) rest input

class ReverseList :: TokenList -> TokenList -> TokenList -> Constraint
class ReverseList input accumulated result | input accumulated -> result

instance ReverseList TNil accumulated accumulated
else instance
  ReverseList rest (TCons token accumulated) result =>
  ReverseList (TCons token rest) accumulated result

-- Positional arity is determined against the minimum cardinality of the
-- suffix. This makes a leading Many/Some greedy without stealing required
-- operands from that suffix (for example SOURCE... DEST).
data Nat
foreign import data Z :: Nat
foreign import data S :: Nat -> Nat

class Minimum :: Positionals -> Nat -> Constraint
class Minimum positionals count | positionals -> count

instance Minimum NoPositionals Z
else instance
  ( Minimum rest count
  , MinimumStep cardinality count result
  ) =>
  Minimum (AddPositional name kind cardinality rest) result

class MinimumStep :: Cardinality -> Nat -> Nat -> Constraint
class MinimumStep cardinality suffix result | cardinality suffix -> result

instance MinimumStep One suffix (S suffix)
else instance MinimumStep Some suffix (S suffix)
else instance MinimumStep Optional suffix suffix
else instance MinimumStep Many suffix suffix

class HasExtra :: TokenList -> Nat -> Boolean -> Constraint
class HasExtra argv minimum result | argv minimum -> result

instance HasExtra TNil Z False
else instance HasExtra (TCons token rest) Z True
else instance HasExtra TNil (S minimum) False
else instance HasExtra rest minimum result => HasExtra (TCons token rest) (S minimum) result

class PositionalsUsage :: Positionals -> Symbol -> Constraint
class PositionalsUsage positionals usage | positionals -> usage

instance PositionalsUsage NoPositionals ""
else instance
  ( CardinalityUsage name cardinality head
  , PositionalsUsage rest tail
  , JoinUsage head tail usage
  ) =>
  PositionalsUsage (AddPositional name kind cardinality rest) usage

class CardinalityUsage :: Symbol -> Cardinality -> Symbol -> Constraint
class CardinalityUsage name cardinality usage | name cardinality -> usage

instance CardinalityUsage name One name
else instance
  ( Symbol.Append "[" name left
  , Symbol.Append left "]" usage
  ) =>
  CardinalityUsage name Optional usage
else instance Symbol.Append name "..." usage => CardinalityUsage name Many usage
else instance Symbol.Append name "..." usage => CardinalityUsage name Some usage

class JoinUsage :: Symbol -> Symbol -> Symbol -> Constraint
class JoinUsage head tail usage | head tail -> usage

instance JoinUsage head "" head
else instance
  ( Symbol.Append head " " prefix
  , Symbol.Append prefix tail usage
  ) =>
  JoinUsage head tail usage

class MatchPositionals
  :: Symbol
  -> Symbol
  -> Positionals
  -> Positionals
  -> TokenList
  -> Row Type
  -> Constraint
class MatchPositionals command usage all current argv input

instance MatchEnd command usage argv => MatchPositionals command usage all NoPositionals argv input
else instance
  MatchCardinality command usage all name kind cardinality rest argv input =>
  MatchPositionals
    command
    usage
    all
    (AddPositional name kind cardinality rest)
    argv
    input

class MatchEnd :: Symbol -> Symbol -> TokenList -> Constraint
class MatchEnd command usage argv

instance MatchEnd command usage TNil
else instance PositionalsArityError command usage => MatchEnd command usage argv

class MatchCardinality
  :: Symbol
  -> Symbol
  -> Positionals
  -> Symbol
  -> ValueKind
  -> Cardinality
  -> Positionals
  -> TokenList
  -> Row Type
  -> Constraint
class MatchCardinality command usage all name kind cardinality rest argv input

instance
  ( CheckToken command context kind token input
  , Symbol.Append "operand " name context
  , MatchPositionals command usage all rest remaining input
  ) =>
  MatchCardinality command usage all name kind One rest (TCons token remaining) input
else instance
  PositionalsArityError command usage =>
  MatchCardinality command usage all name kind One rest TNil input
else instance
  ( Minimum rest minimum
  , HasExtra argv minimum consume
  , MatchOptional consume command usage all name kind rest argv input
  ) =>
  MatchCardinality command usage all name kind Optional rest argv input
else instance
  ( Minimum rest minimum
  , HasExtra argv minimum consume
  , MatchMany consume command usage all name kind rest argv input
  ) =>
  MatchCardinality command usage all name kind Many rest argv input
else instance
  ( Minimum rest minimum
  , HasExtra argv minimum consume
  , MatchSome consume command usage all name kind rest argv input
  ) =>
  MatchCardinality command usage all name kind Some rest argv input

class MatchOptional
  :: Boolean
  -> Symbol
  -> Symbol
  -> Positionals
  -> Symbol
  -> ValueKind
  -> Positionals
  -> TokenList
  -> Row Type
  -> Constraint
class MatchOptional consume command usage all name kind rest argv input

instance MatchPositionals command usage all rest argv input =>
  MatchOptional False command usage all name kind rest argv input
else instance
  ( CheckToken command context kind token input
  , Symbol.Append "operand " name context
  , MatchPositionals command usage all rest remaining input
  ) =>
  MatchOptional True command usage all name kind rest (TCons token remaining) input

class MatchMany
  :: Boolean
  -> Symbol
  -> Symbol
  -> Positionals
  -> Symbol
  -> ValueKind
  -> Positionals
  -> TokenList
  -> Row Type
  -> Constraint
class MatchMany consume command usage all name kind rest argv input

instance MatchPositionals command usage all rest argv input =>
  MatchMany False command usage all name kind rest argv input
else instance
  ( CheckToken command context kind token input
  , Symbol.Append "operand " name context
  , MatchCardinality command usage all name kind Many rest remaining input
  ) =>
  MatchMany True command usage all name kind rest (TCons token remaining) input

class MatchSome
  :: Boolean
  -> Symbol
  -> Symbol
  -> Positionals
  -> Symbol
  -> ValueKind
  -> Positionals
  -> TokenList
  -> Row Type
  -> Constraint
class MatchSome consume command usage all name kind rest argv input

instance PositionalsArityError command usage =>
  MatchSome False command usage all name kind rest argv input
else instance
  ( CheckToken command context kind token input
  , Symbol.Append "operand " name context
  , MatchCardinality command usage all name kind Many rest remaining input
  ) =>
  MatchSome True command usage all name kind rest (TCons token remaining) input

class PositionalsArityError :: Symbol -> Symbol -> Constraint
class PositionalsArityError command usage

instance
  Fail
    (Beside (Beside (Text command) (Text " expects ")) (Text usage)) =>
  PositionalsArityError command usage

-- Semantic checking ---------------------------------------------------------

class CheckToken :: Symbol -> Symbol -> ValueKind -> Token -> Row Type -> Constraint
class CheckToken command context kind token input

instance CheckPieces command context kind pieces input =>
  CheckToken command context kind (Word pieces) input

class CheckPieces :: Symbol -> Symbol -> ValueKind -> Pieces -> Row Type -> Constraint
class CheckPieces command context kind pieces input

instance CheckTextPieces command context pieces input =>
  CheckPieces command context TextValue pieces input
else instance
  ResolveExpected command context IntValue path input =>
  CheckPieces command context IntValue (SnocPiece NilPieces (Hole path)) input
else instance
  ResolveExpected command context NumberValue path input =>
  CheckPieces command context NumberValue (SnocPiece NilPieces (Hole path)) input
else instance
  ResolveExpected command context BooleanValue path input =>
  CheckPieces command context BooleanValue (SnocPiece NilPieces (Hole path)) input
else instance
  ResolveExpected command context CharValue path input =>
  CheckPieces command context CharValue (SnocPiece NilPieces (Hole path)) input
else instance
  CheckLiteral command context IntValue literal =>
  CheckPieces command context IntValue (SnocPiece NilPieces (Literal literal)) input
else instance
  CheckLiteral command context NumberValue literal =>
  CheckPieces command context NumberValue (SnocPiece NilPieces (Literal literal)) input
else instance
  CheckLiteral command context BooleanValue literal =>
  CheckPieces command context BooleanValue (SnocPiece NilPieces (Literal literal)) input
else instance
  CheckLiteral command context CharValue literal =>
  CheckPieces command context CharValue (SnocPiece NilPieces (Literal literal)) input
else instance ExpectedError command context kind => CheckPieces command context kind pieces input

class CheckTextPieces :: Symbol -> Symbol -> Pieces -> Row Type -> Constraint
class CheckTextPieces command context pieces input

instance CheckTextPieces command context NilPieces input
else instance
  ( CheckTextPieces command context prefix input
  , CheckTextPiece command context piece input
  ) =>
  CheckTextPieces command context (SnocPiece prefix piece) input

class CheckTextPiece :: Symbol -> Symbol -> Piece -> Row Type -> Constraint
class CheckTextPiece command context piece input

instance CheckTextPiece command context (Literal literal) input
else instance ResolveExpected command context TextValue path input =>
  CheckTextPiece command context (Hole path) input

class ResolveExpected :: Symbol -> Symbol -> ValueKind -> Symbol -> Row Type -> Constraint
class ResolveExpected command context kind path input

instance
  ( Symbol.Cons head tail path
  , SplitPath head tail "" hasDot field rest
  , ResolveExpectedPart hasDot command context kind field rest input
  ) =>
  ResolveExpected command context kind path input

class SplitPath :: Symbol -> Symbol -> Symbol -> Boolean -> Symbol -> Symbol -> Constraint
class SplitPath head tail accumulated hasDot field rest
  | head tail accumulated -> hasDot field rest

instance SplitPath "." tail accumulated True accumulated tail
else instance Symbol.Append accumulated head field =>
  SplitPath head "" accumulated False field ""
else instance
  ( Symbol.Append accumulated head accumulated'
  , Symbol.Cons next rest' tail
  , SplitPath next rest' accumulated' hasDot field rest
  ) =>
  SplitPath head tail accumulated hasDot field rest

class ResolveExpectedPart
  :: Boolean
  -> Symbol
  -> Symbol
  -> ValueKind
  -> Symbol
  -> Symbol
  -> Row Type
  -> Constraint
class ResolveExpectedPart hasDot command context kind field rest input

instance
  ( Row.Cons field value tail input
  , ExactValue command context kind value
  ) =>
  ResolveExpectedPart False command context kind field rest input
else instance
  ( Row.Cons field (Record nested) tail input
  , ResolveExpected command context kind rest nested
  ) =>
  ResolveExpectedPart True command context kind field rest input

class ExactValue :: Symbol -> Symbol -> ValueKind -> Type -> Constraint
class ExactValue command context kind value

instance ExactValue command context TextValue String
else instance ExactValue command context IntValue Int
else instance ExactValue command context NumberValue Number
else instance ExactValue command context BooleanValue Boolean
else instance ExactValue command context CharValue Char
else instance ExpectedError command context kind => ExactValue command context kind value

class KindName :: ValueKind -> Symbol -> Constraint
class KindName kind name | kind -> name

instance KindName TextValue "String"
else instance KindName IntValue "Int"
else instance KindName NumberValue "Number"
else instance KindName BooleanValue "Boolean"
else instance KindName CharValue "Char"

class ExpectedError :: Symbol -> Symbol -> ValueKind -> Constraint
class ExpectedError command context kind

instance
  ( KindName kind expected
  , Fail
      ( Beside
          (Beside (Beside (Beside (Text command) (Text " ")) (Text context)) (Text " expects "))
          (Text expected)
      )
  ) =>
  ExpectedError command context kind

class CheckLiteral :: Symbol -> Symbol -> ValueKind -> Symbol -> Constraint
class CheckLiteral command context kind literal

instance CheckLiteral command context TextValue literal
else instance
  ( IsIntLiteral literal valid
  , CheckLiteralResult valid command context IntValue
  ) =>
  CheckLiteral command context IntValue literal
else instance
  ( IsNumberLiteral literal valid
  , CheckLiteralResult valid command context NumberValue
  ) =>
  CheckLiteral command context NumberValue literal
else instance CheckLiteral command context BooleanValue "true"
else instance CheckLiteral command context BooleanValue "false"
else instance ExpectedError command context BooleanValue =>
  CheckLiteral command context BooleanValue literal
else instance
  ( IsCharLiteral literal valid
  , CheckLiteralResult valid command context CharValue
  ) =>
  CheckLiteral command context CharValue literal

class CheckLiteralResult :: Boolean -> Symbol -> Symbol -> ValueKind -> Constraint
class CheckLiteralResult valid command context kind

instance CheckLiteralResult True command context kind
else instance ExpectedError command context kind => CheckLiteralResult False command context kind

class IsIntLiteral :: Symbol -> Boolean -> Constraint
class IsIntLiteral literal valid | literal -> valid

instance IsIntLiteral "" False
else instance
  ( Symbol.Cons head tail literal
  , IntLiteralStart head tail literal valid
  ) =>
  IsIntLiteral literal valid

class IntLiteralStart :: Symbol -> Symbol -> Symbol -> Boolean -> Constraint
class IntLiteralStart head tail literal valid | head tail literal -> valid

instance Digits tail valid => IntLiteralStart "-" tail literal valid
else instance Digits tail valid => IntLiteralStart "+" tail literal valid
else instance Digits literal valid => IntLiteralStart head tail literal valid

class IsCharLiteral :: Symbol -> Boolean -> Constraint
class IsCharLiteral literal valid | literal -> valid

instance IsCharLiteral "" False
else instance
  ( Symbol.Cons char tail literal
  , IsEmpty tail valid
  ) =>
  IsCharLiteral literal valid

class IsEmpty :: Symbol -> Boolean -> Constraint
class IsEmpty symbol valid | symbol -> valid

instance IsEmpty "" True
else instance IsEmpty symbol False

class Digits :: Symbol -> Boolean -> Constraint
class Digits literal valid | literal -> valid

instance Digits "" False
else instance
  ( Symbol.Cons head tail literal
  , IsDigit head digit
  , DigitsRest digit tail valid
  ) =>
  Digits literal valid

class DigitsRest :: Boolean -> Symbol -> Boolean -> Constraint
class DigitsRest digit tail valid | digit tail -> valid

instance DigitsRest False tail False
else instance DigitsRest True "" True
else instance Digits tail valid => DigitsRest True tail valid

class IsDigit :: Symbol -> Boolean -> Constraint
class IsDigit char valid | char -> valid

instance IsDigit "0" True
else instance IsDigit "1" True
else instance IsDigit "2" True
else instance IsDigit "3" True
else instance IsDigit "4" True
else instance IsDigit "5" True
else instance IsDigit "6" True
else instance IsDigit "7" True
else instance IsDigit "8" True
else instance IsDigit "9" True
else instance IsDigit char False

-- Number accepts signed integer and decimal notation. Exponents are parsed as
-- a signed integer suffix. At least one mantissa digit is required.
class IsNumberLiteral :: Symbol -> Boolean -> Constraint
class IsNumberLiteral literal valid | literal -> valid

instance IsNumberLiteral "" False
else instance
  ( Symbol.Cons head tail literal
  , NumberLiteralStart head tail literal valid
  ) =>
  IsNumberLiteral literal valid

class NumberLiteralStart :: Symbol -> Symbol -> Symbol -> Boolean -> Constraint
class NumberLiteralStart head tail literal valid | head tail literal -> valid

instance NumberBody tail valid => NumberLiteralStart "-" tail literal valid
else instance NumberBody tail valid => NumberLiteralStart "+" tail literal valid
else instance NumberBody literal valid => NumberLiteralStart head tail literal valid

class NumberBody :: Symbol -> Boolean -> Constraint
class NumberBody literal valid | literal -> valid

instance NumberScan literal False False valid => NumberBody literal valid

class NumberScan :: Symbol -> Boolean -> Boolean -> Boolean -> Constraint
class NumberScan literal sawDigit sawDot valid | literal sawDigit sawDot -> valid

instance NumberFinish sawDigit valid => NumberScan "" sawDigit sawDot valid
else instance
  ( Symbol.Cons head tail literal
  , NumberChar head tail sawDigit sawDot valid
  ) =>
  NumberScan literal sawDigit sawDot valid

class NumberFinish :: Boolean -> Boolean -> Constraint
class NumberFinish sawDigit valid | sawDigit -> valid

instance NumberFinish True True
else instance NumberFinish False False

class NumberChar :: Symbol -> Symbol -> Boolean -> Boolean -> Boolean -> Constraint
class NumberChar head tail sawDigit sawDot valid
  | head tail sawDigit sawDot -> valid

instance NumberScan tail True sawDot valid => NumberChar "0" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "1" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "2" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "3" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "4" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "5" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "6" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "7" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "8" tail sawDigit sawDot valid
else instance NumberScan tail True sawDot valid => NumberChar "9" tail sawDigit sawDot valid
else instance NumberDot sawDot tail sawDigit valid => NumberChar "." tail sawDigit sawDot valid
else instance NumberExponent sawDigit tail valid => NumberChar "e" tail sawDigit sawDot valid
else instance NumberExponent sawDigit tail valid => NumberChar "E" tail sawDigit sawDot valid
else instance NumberChar head tail sawDigit sawDot False

class NumberDot :: Boolean -> Symbol -> Boolean -> Boolean -> Constraint
class NumberDot sawDot tail sawDigit valid | sawDot tail sawDigit -> valid

instance NumberDot True tail sawDigit False
else instance NumberScan tail sawDigit True valid => NumberDot False tail sawDigit valid

class NumberExponent :: Boolean -> Symbol -> Boolean -> Constraint
class NumberExponent sawDigit tail valid | sawDigit tail -> valid

instance NumberExponent False tail False
else instance IsIntLiteral tail valid => NumberExponent True tail valid
