module Script.Command.Grammar
  ( Grammar
  , Command
  , ValueKind
  , TextValue
  , IntValue
  , NumberValue
  , BooleanValue
  , CharValue
  , Operand
  , NoOperand
  , RequiredOperand
  , Repeat
  , Once
  , Repeatable
  , Names
  , NoNames
  , Name
  , Options
  , NoOptions
  , AddOption
  , Cardinality
  , One
  , Optional
  , Many
  , Some
  , Positionals
  , NoPositionals
  , AddPositional
  , Subcommands
  , NoSubcommands
  , AddSubcommand
  ) where



data ValueKind
foreign import data TextValue :: ValueKind
foreign import data IntValue :: ValueKind
foreign import data NumberValue :: ValueKind
foreign import data BooleanValue :: ValueKind
foreign import data CharValue :: ValueKind

data Operand
foreign import data NoOperand :: Operand
foreign import data RequiredOperand :: ValueKind -> Operand

data Repeat
foreign import data Once :: Repeat
foreign import data Repeatable :: Repeat

data Names
foreign import data NoNames :: Names
foreign import data Name :: Symbol -> Names -> Names

data Options
foreign import data NoOptions :: Options
foreign import data AddOption :: Names -> Operand -> Repeat -> Options -> Options

data Cardinality
foreign import data One :: Cardinality
foreign import data Optional :: Cardinality
foreign import data Many :: Cardinality
foreign import data Some :: Cardinality

data Positionals
foreign import data NoPositionals :: Positionals
foreign import data AddPositional :: Symbol -> ValueKind -> Cardinality -> Positionals -> Positionals

data Subcommands
foreign import data NoSubcommands :: Subcommands
foreign import data AddSubcommand :: Symbol -> Grammar -> Subcommands -> Subcommands

data Grammar
foreign import data Command :: Symbol -> Options -> Positionals -> Subcommands -> Grammar

