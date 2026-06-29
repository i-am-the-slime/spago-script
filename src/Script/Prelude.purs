module Script.Prelude
  ( module Prelude
  , (/)
  , module Data.Either
  , module Data.Maybe
  , module Effect
  , module Effect.Aff.Class
  , module Effect.Class
  , module Node.Buffer
  , module Node.ChildProcess.Types
  , module Node.Encoding
  , module Node.FS.Stats
  , module Node.Path
  , module Yoga.Format
  , module Yoga.Om
  , class CmdArgs
  , class KnownArgs
  , class KnownTemplateArgs
  , class LsArgs
  , class RmArgs
  , class ToArgs
  , class ValidateLsArgs
  , class ValidateLsPlainToken
  , class ValidateLsPlainTokenChar
  , class ValidateLsToken
  , class ValidateLsFlag
  , class ValidateLsFlagToken
  , class ValidateRmArgs
  , class ValidateRmFlag
  , class ValidateRmFlagToken
  , class ValidateRmPlainToken
  , class ValidateRmPlainTokenChar
  , class ValidateCommandArgs
  , class ValidateCommandFlag
  , class ValidateCommandFlagToken
  , class ValidateCommandPlainToken
  , class ValidateCommandPlainTokenChar
  , class ValidateCommandToken
  , class ValidateRmToken
  , cmdKnownArgs
  , knownArgs
  , lsKnownArgs
  , rmKnownArgs
  , templateArgs
  , toArgs
  , CommandResult
  , ExecaOptions
  , ExecaProcess
  , ExecaResult
  , access
  , append
  , appendFile
  , appendTextFile
  , appendTextFileWith
  , args
  , cat
  , cmd
  , cmd_
  , cmdHere
  , cmdPipe
  , cmdWith
  , copy
  , copyFile
  , cp
  , cp_
  , cpArgs
  , cwd
  , directoryExists
  , env
  , execa
  , execaWith
  , exec
  , exists
  , exit
  , choose
  , confirm
  , ensureGum
  , fileExists
  , go
  , gum
  , gum_
  , gumChoose
  , gumConfirm
  , gumFilter
  , gumInput
  , grep
  , grep_
  , grepArgs
  , gh
  , gh_
  , ghArgs
  , gumSpin
  , head
  , head_
  , headArgs
  , here
  , input
  , isDir
  , jj
  , jj_
  , jjArgs
  , isFile
  , launch
  , link
  , listDir
  , log
  , logError
  , logFmt
  , logShow
  , lookupEnv
  , lstat
  , find
  , find_
  , findArgs
  , git
  , git_
  , gitArgs
  , ls
  , ls_
  , lsArgs
  , mv
  , mv_
  , mvArgs
  , mkdir
  , mkdir_
  , mkdirArgs
  , purs
  , purs_
  , pursArgs
  , pursTidy
  , pursTidy_
  , pursTidyArgs
  , mkdirp
  , mkdtemp
  , pathJoin
  , pipeFrom
  , pipeInto
  , read
  , readFile
  , readlink
  , rename
  , readTextFile
  , readTextFileWith
  , realpath
  , removeDir
  , removeFile
  , requireEnv
  , rm
  , rm_
  , rmArgs
  , run
  , runAff
  , runAffWith
  , runWith
  , rmdir
  , rg
  , rg_
  , rgArgs
  , sed
  , sed_
  , sedArgs
  , sh
  , sort
  , sort_
  , sortArgs
  , spago
  , spago_
  , spagoArgs
  , spawn
  , spawnHere
  , spawnPipe
  , spawnWith
  , stat
  , select
  , spin
  , stream
  , style
  , symlink
  , tail
  , tail_
  , tailArgs
  , tee
  , tee_
  , teeArgs
  , touch
  , touch_
  , touchArgs
  , truncate
  , uniq
  , uniq_
  , uniqArgs
  , unlink
  , wc
  , wc_
  , wcArgs
  , which
  , which_
  , whichArgs
  , write
  , writeFile
  , writeTextFile
  , writeTextFileWith
  , x
  , (<|)
  , (|>)
  , x_
  , xHere
  , xPipe
  , xWith
  ) where

import Prelude hiding (append, (/))

import Control.Monad.Reader.Trans (asks)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), maybe)
import Data.Nullable (Nullable, toMaybe)
import Data.String as String
import Data.String.Regex as Regex
import Data.String.Regex.Flags (noFlags)
import Data.String.Regex.Unsafe (unsafeRegex)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Prim.Symbol as Symbol
import Prim.TypeError (class Fail, Text, Beside)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console as Console
import Effect.Exception as Exception
import Node.Buffer (Buffer)
import Node.Buffer (Buffer) as Node.Buffer
import Node.ChildProcess.Types (pipe) as ChildProcess
import Node.ChildProcess.Types (Exit(..), StdIO, inherit)
import Node.ChildProcess.Types (Exit(..), KillSignal, StdIO, customShell, defaultStdIO, enableShell, fileDescriptor, fileDescriptor', ignore, inherit, intSignal, ipc, overlapped, pipe, shareStream, stringSignal) as Node.ChildProcess.Types
import Node.Encoding (Encoding(..))
import Node.Encoding (Encoding(..)) as Node.Encoding
import Node.FS (SymlinkType)
import Node.FS.Aff as FS
import Node.FS.Perms as Perms
import Node.FS.Stats (Stats)
import Node.FS.Stats as Stats
import Node.FS.Stats (Stats) as Node.FS.Stats
import Node.Library.Execa as Execa
import Node.Path (FilePath)
import Node.Path (FilePath) as Node.Path
import Node.Path as Path
import Type.Proxy (Proxy(..))
import Yoga.Format (class ParseTemplate, fmt, format)
import Yoga.Format (fmt, format) as Yoga.Format
import Yoga.Format.Render (class RenderInput)
import Yoga.Om (Om)
import Yoga.Om (Om(..), ParOm(..), delay, error, expand, expandCtx, expandErr, fatal, fromAff, handleErrors, handleErrors', inParallel, launchOm, launchOm_, mapError, note, noteM, onError, orFail, parOmToAff, race, readerT, runOm, runOmOrThrow, runOmRecord, runOms, runOmsInOm, runReader, sequenceOmRecord, tap, tapM, throw, throwLeftAs, throwLeftAsM, toOm, unliftAff, unliftAffFn, widenCtx) as Yoga.Om


type CommandResult =
  { code :: Int
  , stdout :: String
  , stderr :: String
  }

type ExecaOptions = Execa.ExecaOptions

type ExecaProcess = Execa.ExecaProcess

type ExecaResult = Execa.ExecaResult

class KnownArgs (args :: Symbol) where
  knownArgs :: Array String

instance IsSymbol args => KnownArgs args where
  knownArgs = splitArgs $ reflectSymbol (Proxy :: Proxy args)

class KnownTemplateArgs (args :: Symbol) input where
  templateArgs :: input -> Array String

instance
  ( IsSymbol args
  , ParseTemplate args segments
  , RenderInput segments input
  ) =>
  KnownTemplateArgs args input where
  templateArgs values = splitArgs $ fmt @args values

class LsArgs (args :: Symbol) where
  lsKnownArgs :: Array String

instance (IsSymbol args, ValidateLsArgs args) => LsArgs args where
  lsKnownArgs = splitArgs $ reflectSymbol (Proxy :: Proxy args)

class ValidateLsArgs :: Symbol -> Constraint
class ValidateLsArgs args

instance ValidateLsArgs ""
else instance (Symbol.Cons head tail args, ValidateLsToken head tail) => ValidateLsArgs args

class ValidateLsToken :: Symbol -> Symbol -> Constraint
class ValidateLsToken head tail

instance ValidateLsArgs tail => ValidateLsToken " " tail
else instance ValidateLsFlagToken tail => ValidateLsToken "-" tail
else instance ValidateLsPlainToken tail => ValidateLsToken head tail

class ValidateLsPlainToken :: Symbol -> Constraint
class ValidateLsPlainToken args

instance ValidateLsPlainToken ""
else instance (Symbol.Cons head tail args, ValidateLsPlainTokenChar head tail) => ValidateLsPlainToken args

class ValidateLsPlainTokenChar :: Symbol -> Symbol -> Constraint
class ValidateLsPlainTokenChar head tail

instance ValidateLsArgs tail => ValidateLsPlainTokenChar " " tail
else instance ValidateLsPlainToken tail => ValidateLsPlainTokenChar head tail

class ValidateLsFlagToken :: Symbol -> Constraint
class ValidateLsFlagToken args

instance ValidateLsFlagToken ""
else instance (Symbol.Cons head tail args, ValidateLsFlag head tail) => ValidateLsFlagToken args

class ValidateLsFlag :: Symbol -> Symbol -> Constraint
class ValidateLsFlag head tail

instance ValidateLsArgs tail => ValidateLsFlag " " tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "1" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "@" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "A" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "B" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "C" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "F" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "G" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "H" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "L" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "O" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "P" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "R" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "S" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "T" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "U" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "W" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "a" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "b" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "c" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "d" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "e" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "f" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "g" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "h" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "i" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "k" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "l" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "m" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "n" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "o" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "p" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "q" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "r" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "s" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "t" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "u" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "v" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "w" tail
else instance ValidateLsFlagToken tail => ValidateLsFlag "x" tail
else instance Fail (Beside (Text "Illegal ls option: -") (Text flag)) => ValidateLsFlag flag tail

class RmArgs (args :: Symbol) where
  rmKnownArgs :: Array String

instance (IsSymbol args, ValidateRmArgs args) => RmArgs args where
  rmKnownArgs = splitArgs $ reflectSymbol (Proxy :: Proxy args)

class ValidateRmArgs :: Symbol -> Constraint
class ValidateRmArgs args

instance ValidateRmArgs ""
else instance (Symbol.Cons head tail args, ValidateRmToken head tail) => ValidateRmArgs args

class ValidateRmToken :: Symbol -> Symbol -> Constraint
class ValidateRmToken head tail

instance ValidateRmArgs tail => ValidateRmToken " " tail
else instance ValidateRmFlagToken tail => ValidateRmToken "-" tail
else instance ValidateRmPlainToken tail => ValidateRmToken head tail

class ValidateRmPlainToken :: Symbol -> Constraint
class ValidateRmPlainToken args

instance ValidateRmPlainToken ""
else instance (Symbol.Cons head tail args, ValidateRmPlainTokenChar head tail) => ValidateRmPlainToken args

class ValidateRmPlainTokenChar :: Symbol -> Symbol -> Constraint
class ValidateRmPlainTokenChar head tail

instance ValidateRmArgs tail => ValidateRmPlainTokenChar " " tail
else instance ValidateRmPlainToken tail => ValidateRmPlainTokenChar head tail

class ValidateRmFlagToken :: Symbol -> Constraint
class ValidateRmFlagToken args

instance ValidateRmFlagToken ""
else instance (Symbol.Cons head tail args, ValidateRmFlag head tail) => ValidateRmFlagToken args

class ValidateRmFlag :: Symbol -> Symbol -> Constraint
class ValidateRmFlag head tail

instance ValidateRmArgs tail => ValidateRmFlag " " tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "P" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "R" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "W" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "d" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "f" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "i" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "r" tail
else instance ValidateRmFlagToken tail => ValidateRmFlag "v" tail
else instance Fail (Beside (Text "Illegal rm option: -") (Text flag)) => ValidateRmFlag flag tail

class CmdArgs (command :: Symbol) (args :: Symbol) where
  cmdKnownArgs :: Array String

instance (IsSymbol args, ValidateCommandArgs command args) => CmdArgs command args where
  cmdKnownArgs = splitArgs $ reflectSymbol (Proxy :: Proxy args)

class ValidateCommandArgs :: Symbol -> Symbol -> Constraint
class ValidateCommandArgs command args

instance ValidateCommandArgs command ""
else instance (Symbol.Cons head tail args, ValidateCommandToken command head tail) => ValidateCommandArgs command args

class ValidateCommandToken :: Symbol -> Symbol -> Symbol -> Constraint
class ValidateCommandToken command head tail

instance ValidateCommandArgs command tail => ValidateCommandToken command " " tail
else instance ValidateCommandFlagToken command tail => ValidateCommandToken command "-" tail
else instance ValidateCommandPlainToken command tail => ValidateCommandToken command head tail

class ValidateCommandPlainToken :: Symbol -> Symbol -> Constraint
class ValidateCommandPlainToken command args

instance ValidateCommandPlainToken command ""
else instance (Symbol.Cons head tail args, ValidateCommandPlainTokenChar command head tail) => ValidateCommandPlainToken command args

class ValidateCommandPlainTokenChar :: Symbol -> Symbol -> Symbol -> Constraint
class ValidateCommandPlainTokenChar command head tail

instance ValidateCommandArgs command tail => ValidateCommandPlainTokenChar command " " tail
else instance ValidateCommandPlainToken command tail => ValidateCommandPlainTokenChar command head tail

class ValidateCommandFlagToken :: Symbol -> Symbol -> Constraint
class ValidateCommandFlagToken command args

instance ValidateCommandFlagToken command ""
else instance (Symbol.Cons head tail args, ValidateCommandFlag command head tail) => ValidateCommandFlagToken command args

class ValidateCommandFlag :: Symbol -> Symbol -> Symbol -> Constraint
class ValidateCommandFlag command head tail

instance ValidateCommandArgs command tail => ValidateCommandFlag command " " tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag command "-" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "H" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "L" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "P" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "R" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "X" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "cp" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mv" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mv" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mv" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mv" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mkdir" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mkdir" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "mkdir" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "A" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "B" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "C" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "E" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "F" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "H" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "I" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "L" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "R" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "V" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "b" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "o" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "w" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "grep" "x" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "H" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "L" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "P" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "X" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "d" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "find" "x" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "V" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "b" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "d" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "g" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "k" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "o" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "u" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sort" "z" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "d" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "uniq" "u" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "b" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "d" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "g" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "o" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "u" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "w" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "x" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "y" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "git" "z" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "b" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "d" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "o" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "u" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "spago" "x" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "A" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "B" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "C" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "F" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "H" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "I" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "L" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "M" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "N" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "P" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "S" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "U" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "V" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "g" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "j" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "o" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "p" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "s" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "u" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "w" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "rg" "x" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "E" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "e" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "sed" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "head" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "head" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "head" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "head" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "F" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "f" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "n" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "q" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tail" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "wc" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "wc" "l" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "wc" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "wc" "w" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tee" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "tee" "i" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "A" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "c" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "m" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "r" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "touch" "t" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "which" "a" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "jj" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "jj" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "gh" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "gh" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "purs" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "purs" "v" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "purs-tidy" "h" tail
else instance ValidateCommandFlagToken command tail => ValidateCommandFlag "purs-tidy" "v" tail
else instance Fail (Beside (Beside (Text "Illegal option for ") (Text command)) (Beside (Text ": -") (Text flag))) => ValidateCommandFlag command flag tail

class ToArgs args where
  toArgs :: args -> Array String

instance ToArgs String where
  toArgs = splitArgs

instance ToArgs (Array String) where
  toArgs = identity

splitArgs :: String -> Array String
splitArgs = Regex.split whitespace >>> Array.filter (_ /= "")
  where
  whitespace = unsafeRegex "\\s+" noFlags

log :: forall m. MonadEffect m => String -> m Unit
log = Console.log

logError :: forall m. MonadEffect m => String -> m Unit
logError = Console.error

logShow :: forall m a. MonadEffect m => Show a => a -> m Unit
logShow = Console.logShow

logFmt
  :: forall @tmpl segments input m
   . IsSymbol tmpl
  => ParseTemplate tmpl segments
  => RenderInput segments input
  => MonadEffect m
  => input
  -> m Unit
logFmt = log <<< fmt @tmpl

infixl 5 pathJoin as /

pathJoin :: FilePath -> FilePath -> FilePath
pathJoin left right = Path.concat [ left, right ]

launch :: Aff Unit -> Effect Unit
launch script = Aff.runAff_ finish script
  where
  finish = case _ of
    Left err -> do
      logError (Exception.message err)
      exit 1
    Right _ -> pure unit

run :: Om {} () Unit -> Effect Unit
run = runWith {}

runWith :: forall ctx. ctx -> Om ctx () Unit -> Effect Unit
runWith ctx = launch <<< runAffWith ctx

runAff :: forall a. Om {} () a -> Aff a
runAff = runAffWith {}

runAffWith :: forall ctx a. ctx -> Om ctx () a -> Aff a
runAffWith = Yoga.Om.runOmOrThrow

go :: Om {} () Unit -> Effect Unit
go = run

here :: forall ctx err. Om { cwd :: FilePath | ctx } err FilePath
here = asks _.cwd

args :: Effect (Array String)
args = argvImpl

foreign import argvImpl :: Effect (Array String)

cwd :: Effect FilePath
cwd = cwdImpl

foreign import cwdImpl :: Effect FilePath

lookupEnv :: String -> Effect (Maybe String)
lookupEnv name = toMaybe <$> envImpl name

foreign import envImpl :: String -> Effect (Nullable String)

env :: forall m. MonadAff m => String -> m String
env = requireEnv

requireEnv :: forall m. MonadAff m => String -> m String
requireEnv name = do
  value <- lookupEnv name # liftEffect
  maybe (failWith $ "Missing environment variable: " <> name) pure value

exit :: Int -> Effect Unit
exit = exitImpl

foreign import exitImpl :: Int -> Effect Unit

access :: forall m. MonadAff m => FilePath -> m (Maybe Exception.Error)
access path = FS.access path # liftAff

copyFile :: forall m. MonadAff m => FilePath -> FilePath -> m Unit
copyFile from to = FS.copyFile from to # liftAff

copy :: forall m. MonadAff m => FilePath -> FilePath -> m Unit
copy = copyFile

mkdtemp :: forall m. MonadAff m => String -> m FilePath
mkdtemp prefix = FS.mkdtemp prefix # liftAff

rename :: forall m. MonadAff m => FilePath -> FilePath -> m Unit
rename from to = FS.rename from to # liftAff

truncate :: forall m. MonadAff m => FilePath -> Int -> m Unit
truncate path length = FS.truncate path length # liftAff

stat :: forall m. MonadAff m => FilePath -> m Stats
stat path = FS.stat path # liftAff

lstat :: forall m. MonadAff m => FilePath -> m Stats
lstat path = FS.lstat path # liftAff

link :: forall m. MonadAff m => FilePath -> FilePath -> m Unit
link existing next = FS.link existing next # liftAff

symlink :: forall m. MonadAff m => FilePath -> FilePath -> SymlinkType -> m Unit
symlink target path kind = FS.symlink target path kind # liftAff

readlink :: forall m. MonadAff m => FilePath -> m FilePath
readlink path = FS.readlink path # liftAff

realpath :: forall m. MonadAff m => FilePath -> m FilePath
realpath path = FS.realpath path # liftAff

unlink :: forall m. MonadAff m => FilePath -> m Unit
unlink path = FS.unlink path # liftAff

rmdir :: forall m. MonadAff m => FilePath -> m Unit
rmdir path = FS.rmdir path # liftAff

rm :: forall @args input m. RmArgs args => KnownTemplateArgs args input => MonadAff m => input -> m Unit
rm values = x_ "rm" (templateArgs @args values)

rm_ :: forall @args m. RmArgs args => MonadAff m => m Unit
rm_ = x_ "rm" (rmKnownArgs @args)

rmArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
rmArgs = x_ "rm"

mkdir :: forall @args input m. CmdArgs "mkdir" args => KnownTemplateArgs args input => MonadAff m => input -> m Unit
mkdir values = x_ "mkdir" (templateArgs @args values)

mkdir_ :: forall @args m. CmdArgs "mkdir" args => MonadAff m => m Unit
mkdir_ = x_ "mkdir" (cmdKnownArgs @"mkdir" @args)

mkdirArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
mkdirArgs = x_ "mkdir"

mkdirp :: forall m. MonadAff m => FilePath -> m Unit
mkdirp path = FS.mkdir' path { recursive: true, mode: Perms.mkPerms Perms.all Perms.all Perms.all } # liftAff

removeFile :: forall m. MonadAff m => FilePath -> m Unit
removeFile path = FS.rm' path defaultRmOptions # liftAff

removeDir :: forall m. MonadAff m => FilePath -> m Unit
removeDir path = FS.rm' path defaultRmOptions { recursive = true } # liftAff

listDir :: forall m. MonadAff m => FilePath -> m (Array FilePath)
listDir path = FS.readdir path # liftAff

ls :: forall @args input m. LsArgs args => KnownTemplateArgs args input => MonadAff m => input -> m String
ls values = x "ls" (templateArgs @args values)

ls_ :: forall @args m. LsArgs args => MonadAff m => m String
ls_ = x "ls" (lsKnownArgs @args)

lsArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
lsArgs = x "ls"

readFile :: forall m. MonadAff m => FilePath -> m Buffer
readFile path = FS.readFile path # liftAff

writeFile :: forall m. MonadAff m => FilePath -> Buffer -> m Unit
writeFile path buffer = FS.writeFile path buffer # liftAff

appendFile :: forall m. MonadAff m => FilePath -> Buffer -> m Unit
appendFile path buffer = FS.appendFile path buffer # liftAff

readTextFile :: forall m. MonadAff m => FilePath -> m String
readTextFile = readTextFileWith UTF8

read :: forall m. MonadAff m => FilePath -> m String
read = readTextFile

cat :: forall m. MonadAff m => FilePath -> m String
cat = readTextFile

readTextFileWith :: forall m. MonadAff m => Encoding -> FilePath -> m String
readTextFileWith encoding path = FS.readTextFile encoding path # liftAff

writeTextFile :: forall m. MonadAff m => FilePath -> String -> m Unit
writeTextFile = writeTextFileWith UTF8

write :: forall m. MonadAff m => FilePath -> String -> m Unit
write = writeTextFile

writeTextFileWith :: forall m. MonadAff m => Encoding -> FilePath -> String -> m Unit
writeTextFileWith encoding path contents = FS.writeTextFile encoding path contents # liftAff

appendTextFile :: forall m. MonadAff m => FilePath -> String -> m Unit
appendTextFile = appendTextFileWith UTF8

append :: forall m. MonadAff m => FilePath -> String -> m Unit
append = appendTextFile

appendTextFileWith :: forall m. MonadAff m => Encoding -> FilePath -> String -> m Unit
appendTextFileWith encoding path contents = FS.appendTextFile encoding path contents # liftAff

fileExists :: forall m. MonadAff m => FilePath -> m Boolean
fileExists path = statSatisfies Stats.isFile path

exists :: forall m. MonadAff m => FilePath -> m Boolean
exists = fileExists

isFile :: forall m. MonadAff m => FilePath -> m Boolean
isFile = fileExists

directoryExists :: forall m. MonadAff m => FilePath -> m Boolean
directoryExists path = statSatisfies Stats.isDirectory path

isDir :: forall m. MonadAff m => FilePath -> m Boolean
isDir = directoryExists

spawn :: forall args m. ToArgs args => MonadAff m => String -> args -> m ExecaProcess
spawn file commandArgs = spawnWith file commandArgs identity

spawnWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m ExecaProcess
spawnWith file commandArgs options = Execa.execa file (toArgs commandArgs) options # liftAff

spawnPipe :: forall args m. ToArgs args => MonadAff m => String -> args -> m ExecaProcess
spawnPipe file commandArgs = spawnWith file commandArgs stream

spawnHere :: forall args ctx err. ToArgs args => String -> args -> Om { cwd :: FilePath | ctx } err ExecaProcess
spawnHere file commandArgs = do
  dir <- here
  spawnWith file commandArgs (_ { cwd = Just dir })

execa :: forall args m. ToArgs args => MonadAff m => String -> args -> m ExecaResult
execa file commandArgs = execaWith file commandArgs identity

execaWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m ExecaResult
execaWith file commandArgs options = do
  spawned <- spawnWith file commandArgs options
  result <- spawned.getResult # liftAff
  ensureOk result

x :: forall args m. ToArgs args => MonadAff m => String -> args -> m String
x file commandArgs = _.stdout <$> execa file commandArgs

x_ :: forall args m. ToArgs args => MonadAff m => String -> args -> m Unit
x_ file commandArgs = void $ execa file commandArgs

xWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m String
xWith file commandArgs options = _.stdout <$> execaWith file commandArgs options

xPipe :: forall args m. ToArgs args => MonadAff m => String -> args -> m Unit
xPipe file commandArgs = void $ execaWith file commandArgs stream

xHere :: forall args ctx err. ToArgs args => String -> args -> Om { cwd :: FilePath | ctx } err String
xHere file commandArgs = do
  dir <- here
  xWith file commandArgs (_ { cwd = Just dir })

cmd :: forall m. MonadAff m => String -> m String
cmd command = _.stdout <$> cmdWith command identity

cmd_ :: forall m. MonadAff m => String -> m Unit
cmd_ command = void $ cmdWith command identity

cmdWith :: forall m. MonadAff m => String -> (ExecaOptions -> ExecaOptions) -> m ExecaResult
cmdWith command options = execaWith shell [ "-c", command ] options
  where
  shell = "sh"

cmdPipe :: forall m. MonadAff m => String -> m Unit
cmdPipe command = void $ cmdWith command stream

cmdHere :: forall ctx err. String -> Om { cwd :: FilePath | ctx } err String
cmdHere command = do
  dir <- here
  _.stdout <$> cmdWith command (_ { cwd = Just dir })

gum :: forall args m. ToArgs args => MonadAff m => args -> m String
gum = x gumBin

gum_ :: forall args m. ToArgs args => MonadAff m => args -> m Unit
gum_ = x_ gumBin

ensureGum :: forall m. MonadAff m => m Unit
ensureGum = gum_ "--version"

choose :: forall m. MonadAff m => Array String -> m String
choose = gumChoose

gumChoose :: forall m. MonadAff m => Array String -> m String
gumChoose choices = gum ([ "choose" ] <> choices)

confirm :: forall m. MonadAff m => String -> m Boolean
confirm = gumConfirm

gumConfirm :: forall m. MonadAff m => String -> m Boolean
gumConfirm message = do
  spawned <- spawn gumBin [ "confirm", message ]
  result <- spawned.getResult # liftAff
  case result.exit of
    Normally 0 -> pure true
    _ -> pure false

input :: forall m. MonadAff m => String -> m String
input = gumInput

gumInput :: forall m. MonadAff m => String -> m String
gumInput placeholder = gum [ "input", "--placeholder", placeholder ]

select :: forall m. MonadAff m => Array String -> m String
select = gumFilter

gumFilter :: forall m. MonadAff m => Array String -> m String
gumFilter choices = pipe (String.joinWith "\n" choices) "gum filter"

spin :: forall m. MonadAff m => String -> String -> m String
spin = gumSpin

gumSpin :: forall m. MonadAff m => String -> String -> m String
gumSpin title command = gum [ "spin", "--title", title, "--", "sh", "-c", command ]

style :: forall m. MonadAff m => String -> String -> m String
style foreground text = gum [ "style", "--foreground", foreground, text ]

gumBin :: String
gumBin = "gum"

stream :: ExecaOptions -> ExecaOptions
stream options = options
  { stdin = Just inherit
  , stdout = Just inherit
  , stderr = Just inherit
  }

mv :: forall @args input m. CmdArgs "mv" args => KnownTemplateArgs args input => MonadAff m => input -> m Unit
mv values = x_ "mv" (templateArgs @args values)

mv_ :: forall @args m. CmdArgs "mv" args => MonadAff m => m Unit
mv_ = x_ "mv" (cmdKnownArgs @"mv" @args)

mvArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
mvArgs = x_ "mv"

cp :: forall @args input m. CmdArgs "cp" args => KnownTemplateArgs args input => MonadAff m => input -> m Unit
cp values = x_ "cp" (templateArgs @args values)

cp_ :: forall @args m. CmdArgs "cp" args => MonadAff m => m Unit
cp_ = x_ "cp" (cmdKnownArgs @"cp" @args)

cpArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
cpArgs = x_ "cp"

git :: forall @args input m. CmdArgs "git" args => KnownTemplateArgs args input => MonadAff m => input -> m String
git values = x "git" (templateArgs @args values)

git_ :: forall @args m. CmdArgs "git" args => MonadAff m => m String
git_ = x "git" (cmdKnownArgs @"git" @args)

gitArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
gitArgs = x "git"

spago :: forall @args input m. CmdArgs "spago" args => KnownTemplateArgs args input => MonadAff m => input -> m String
spago values = x "spago" (templateArgs @args values)

spago_ :: forall @args m. CmdArgs "spago" args => MonadAff m => m String
spago_ = x "spago" (cmdKnownArgs @"spago" @args)

spagoArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
spagoArgs = x "spago"

grep :: forall @args input m. CmdArgs "grep" args => KnownTemplateArgs args input => MonadAff m => input -> m String
grep values = x "grep" (templateArgs @args values)

grep_ :: forall @args m. CmdArgs "grep" args => MonadAff m => m String
grep_ = x "grep" (cmdKnownArgs @"grep" @args)

grepArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
grepArgs = x "grep"

find :: forall @args input m. CmdArgs "find" args => KnownTemplateArgs args input => MonadAff m => input -> m String
find values = x "find" (templateArgs @args values)

find_ :: forall @args m. CmdArgs "find" args => MonadAff m => m String
find_ = x "find" (cmdKnownArgs @"find" @args)

findArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
findArgs = x "find"

sort :: forall @args input m. CmdArgs "sort" args => KnownTemplateArgs args input => MonadAff m => input -> m String
sort values = x "sort" (templateArgs @args values)

sort_ :: forall @args m. CmdArgs "sort" args => MonadAff m => m String
sort_ = x "sort" (cmdKnownArgs @"sort" @args)

sortArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
sortArgs = x "sort"

uniq :: forall @args input m. CmdArgs "uniq" args => KnownTemplateArgs args input => MonadAff m => input -> m String
uniq values = x "uniq" (templateArgs @args values)

uniq_ :: forall @args m. CmdArgs "uniq" args => MonadAff m => m String
uniq_ = x "uniq" (cmdKnownArgs @"uniq" @args)

uniqArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
uniqArgs = x "uniq"

rg :: forall @args input m. CmdArgs "rg" args => KnownTemplateArgs args input => MonadAff m => input -> m String
rg values = x "rg" (templateArgs @args values)

rg_ :: forall @args m. CmdArgs "rg" args => MonadAff m => m String
rg_ = x "rg" (cmdKnownArgs @"rg" @args)

rgArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
rgArgs = x "rg"

jj :: forall @args input m. CmdArgs "jj" args => KnownTemplateArgs args input => MonadAff m => input -> m String
jj values = x "jj" (templateArgs @args values)

jj_ :: forall @args m. CmdArgs "jj" args => MonadAff m => m String
jj_ = x "jj" (cmdKnownArgs @"jj" @args)

jjArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
jjArgs = x "jj"

gh :: forall @args input m. CmdArgs "gh" args => KnownTemplateArgs args input => MonadAff m => input -> m String
gh values = x "gh" (templateArgs @args values)

gh_ :: forall @args m. CmdArgs "gh" args => MonadAff m => m String
gh_ = x "gh" (cmdKnownArgs @"gh" @args)

ghArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
ghArgs = x "gh"

purs :: forall @args input m. CmdArgs "purs" args => KnownTemplateArgs args input => MonadAff m => input -> m String
purs values = x "purs" (templateArgs @args values)

purs_ :: forall @args m. CmdArgs "purs" args => MonadAff m => m String
purs_ = x "purs" (cmdKnownArgs @"purs" @args)

pursArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
pursArgs = x "purs"

pursTidy :: forall @args input m. CmdArgs "purs-tidy" args => KnownTemplateArgs args input => MonadAff m => input -> m String
pursTidy values = x "purs-tidy" (templateArgs @args values)

pursTidy_ :: forall @args m. CmdArgs "purs-tidy" args => MonadAff m => m String
pursTidy_ = x "purs-tidy" (cmdKnownArgs @"purs-tidy" @args)

pursTidyArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
pursTidyArgs = x "purs-tidy"

sed :: forall @args input m. CmdArgs "sed" args => KnownTemplateArgs args input => MonadAff m => input -> m String
sed values = x "sed" (templateArgs @args values)

sed_ :: forall @args m. CmdArgs "sed" args => MonadAff m => m String
sed_ = x "sed" (cmdKnownArgs @"sed" @args)

sedArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
sedArgs = x "sed"

head :: forall @args input m. CmdArgs "head" args => KnownTemplateArgs args input => MonadAff m => input -> m String
head values = x "head" (templateArgs @args values)

head_ :: forall @args m. CmdArgs "head" args => MonadAff m => m String
head_ = x "head" (cmdKnownArgs @"head" @args)

headArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
headArgs = x "head"

tail :: forall @args input m. CmdArgs "tail" args => KnownTemplateArgs args input => MonadAff m => input -> m String
tail values = x "tail" (templateArgs @args values)

tail_ :: forall @args m. CmdArgs "tail" args => MonadAff m => m String
tail_ = x "tail" (cmdKnownArgs @"tail" @args)

tailArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
tailArgs = x "tail"

wc :: forall @args input m. CmdArgs "wc" args => KnownTemplateArgs args input => MonadAff m => input -> m String
wc values = x "wc" (templateArgs @args values)

wc_ :: forall @args m. CmdArgs "wc" args => MonadAff m => m String
wc_ = x "wc" (cmdKnownArgs @"wc" @args)

wcArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
wcArgs = x "wc"

tee :: forall @args input m. CmdArgs "tee" args => KnownTemplateArgs args input => MonadAff m => input -> m String
tee values = x "tee" (templateArgs @args values)

tee_ :: forall @args m. CmdArgs "tee" args => MonadAff m => m String
tee_ = x "tee" (cmdKnownArgs @"tee" @args)

teeArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
teeArgs = x "tee"

touch :: forall @args input m. CmdArgs "touch" args => KnownTemplateArgs args input => MonadAff m => input -> m Unit
touch values = x_ "touch" (templateArgs @args values)

touch_ :: forall @args m. CmdArgs "touch" args => MonadAff m => m Unit
touch_ = x_ "touch" (cmdKnownArgs @"touch" @args)

touchArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
touchArgs = x_ "touch"

which :: forall @args input m. CmdArgs "which" args => KnownTemplateArgs args input => MonadAff m => input -> m String
which values = x "which" (templateArgs @args values)

which_ :: forall @args m. CmdArgs "which" args => MonadAff m => m String
which_ = x "which" (cmdKnownArgs @"which" @args)

whichArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
whichArgs = x "which"

infixl 1 pipeInto as |>

pipeInto :: forall m. MonadAff m => m String -> String -> m String
pipeInto source command = do
  stdin <- source
  pipe stdin command

infixr 1 pipeFrom as <|

pipeFrom :: forall m. MonadAff m => String -> m String -> m String
pipeFrom command source = source |> command

pipe :: forall m. MonadAff m => String -> String -> m String
pipe stdin command = do
  spawned <- spawnWith shell [ "-c", command ] (_ { stdin = Just ChildProcess.pipe })
  case spawned.stdin of
    Just childStdin -> childStdin.writeUtf8End stdin # liftAff
    Nothing -> failWith $ "Could not open stdin for command: " <> command
  result <- spawned.getResult # liftAff
  _.stdout <$> ensureOk result
  where
  shell = "sh"

exec :: forall m. MonadAff m => String -> Array String -> m CommandResult
exec command commandArgs = fromEffectFnAff (execImpl command commandArgs) # liftAff

foreign import execImpl :: String -> Array String -> EffectFnAff CommandResult

sh :: forall m. MonadAff m => String -> m String
sh command = do
  result <- exec shell [ "-c", command ]
  if result.code == 0 then pure result.stdout
  else failWith $ failedCommandMessage command result
  where
  shell = "sh"

  failedCommandMessage failedCommand result =
    "Command failed: " <> failedCommand <> "\n" <> result.stderr

ensureOk :: forall m. MonadAff m => ExecaResult -> m ExecaResult
ensureOk result = case result.exit of
  Normally 0 -> pure result
  _ -> failWith result.message

statSatisfies :: forall m. MonadAff m => (Stats -> Boolean) -> FilePath -> m Boolean
statSatisfies predicate path = do
  result <- Aff.try (FS.stat path) # liftAff
  case result of
    Left _ -> pure false
    Right fileStats -> pure $ predicate fileStats

failWith :: forall m a. MonadAff m => String -> m a
failWith message = Aff.throwError (Exception.error message) # liftAff

defaultRmOptions :: { force :: Boolean, maxRetries :: Int, recursive :: Boolean, retryDelay :: Int }
defaultRmOptions =
  { force: true
  , maxRetries: 0
  , recursive: false
  , retryDelay: 100
  }
