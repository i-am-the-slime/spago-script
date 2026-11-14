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
  , module Fetch.Yoga.Json
  , module Yoga.Fetch
  , module Yoga.Fetch.Om
  , module Yoga.JSON
  , module Yoga.Format
  , module Yoga.Om
  , module Script.Prelude.Cookie
  , module Script.Prelude.SQLite
  , module Script.Command.Grammar
  , module Script.Command.Grammars
  , module Script.Command.Typed
  , class ToArgs
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
  , cat_
  , catArgs
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
  , chooseNative
  , confirm
  , confirmNative
  , ensureGum
  , file
  , fileNative
  , fileExists
  , go
  , gum
  , gum_
  , gumChoose
  , gumConfirm
  , gumFile
  , gumFilter
  , gumFormat
  , gumInput
  , gumJoin
  , gumLog
  , gumPager
  , grep
  , grep_
  , grepArgs
  , gh
  , gh_
  , ghArgs
  , gumSpin
  , gumTable
  , gumWrite
  , head
  , head_
  , headArgs
  , here
  , input
  , inputNative
  , isDir
  , jj
  , jj_
  , jjArgs
  , isFile
  , joinText
  , joinTextHorizontal
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
  , markdown
  , multiSelect
  , mkdirp
  , mkdtemp
  , pager
  , pagerNative
  , pathJoin
  , class PipeTarget
  , pipeTarget
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
  , spinNative
  , stream
  , style
  , styleNative
  , symlink
  , table
  , tableNative
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
  , writeNative
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
import Data.Foldable (for_)
import Data.Int as Int
import Data.String as String
import Data.String.CodeUnits as String.CodeUnits
import Data.String.Pattern (Pattern(..))
import Data.String.Regex as Regex
import Data.String.Regex.Flags (noFlags)
import Data.String.Regex.Unsafe (unsafeRegex)
import Data.Symbol (class IsSymbol)
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..))
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console as Console
import Effect.Exception as Exception
import Effect.Ref as Ref
import Effect.Timer as Timer
import Fetch.Yoga.Json (fromJSON) as Fetch.Yoga.Json
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
import Node.Process as Process
import Node.Stream as Stream
import Node.EventEmitter (on)
import Script.Command.Grammar
  ( AddOption
  , AddPositional
  , AddSubcommand
  , BooleanValue
  , Cardinality
  , CharValue
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
  , One
  , Operand
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
  ) as Script.Command.Grammar
import Script.Command.Grammars
  ( CatGrammarDefinition
  , CpGrammarDefinition
  , FindGrammarDefinition
  , GhGrammarDefinition
  , GitGrammarDefinition
  , GrepGrammarDefinition
  , HeadGrammarDefinition
  , JjGrammarDefinition
  , LsGrammarDefinition
  , MkdirGrammarDefinition
  , MvGrammarDefinition
  , PursGrammarDefinition
  , PursTidyGrammarDefinition
  , RgGrammarDefinition
  , RmGrammarDefinition
  , SedGrammarDefinition
  , SortGrammarDefinition
  , SpagoGrammarDefinition
  , TailGrammarDefinition
  , TeeGrammarDefinition
  , TouchGrammarDefinition
  , UniqGrammarDefinition
  , WcGrammarDefinition
  , WhichGrammarDefinition
  )
import Script.Command.Grammars
  ( CatGrammarDefinition
  , CpGrammarDefinition
  , FindGrammarDefinition
  , GhGrammarDefinition
  , GitGrammarDefinition
  , GrepGrammarDefinition
  , HeadGrammarDefinition
  , JjGrammarDefinition
  , LsGrammarDefinition
  , MkdirGrammarDefinition
  , MvGrammarDefinition
  , PursGrammarDefinition
  , PursTidyGrammarDefinition
  , RgGrammarDefinition
  , RmGrammarDefinition
  , SedGrammarDefinition
  , SortGrammarDefinition
  , SpagoGrammarDefinition
  , TailGrammarDefinition
  , TeeGrammarDefinition
  , TouchGrammarDefinition
  , UniqGrammarDefinition
  , WcGrammarDefinition
  , WhichGrammarDefinition
  ) as Script.Command.Grammars
import Script.Command.Typed
  ( CommandInvocation(..)
  , class GrammarCommand
  , class TypedArgs
  , grammarCommand
  , typedArgs
  , typedCommand
  )
import Script.Command.Typed
  ( CommandInvocation(..)
  , class GrammarCommand
  , class TypedArgs
  , grammarCommand
  , typedArgs
  , typedCommand
  ) as Script.Command.Typed
import Script.Prelude.Cookie (Cookie, CookieAttribute, ResponseHeaders, SetCookie, cookie, cookieHeader, cookiesFromHeaders, cookiesFromResponseHeaders, parseCookieHeader, parseSetCookieHeader, setCookie, setCookieHeader) as Script.Prelude.Cookie
import Script.Prelude.SQLite (SQLitePath(..), SQLiteQuery(..), querySQLiteText) as Script.Prelude.SQLite
import Yoga.Fetch (URL(..), Fetch, Response, Method, Headers, Redirect, Credentials, arrayBuffer, defaultFetchOptions, deleteMethod, fetch, getMethod, headMethod, headers, includeCredentials, json, makeHeaders, omitCredentials, patchMethod, postMethod, putMethod, redirectError, redirectFollow, redirectManual, sameOriginCredentials, statusCode, text, url) as Yoga.Fetch
import Yoga.Fetch.Om (class DeriveClient, class DeriveClientFn, class DeriveClientRL, class RecordRow, class ToHeaders, client, deriveClient, deriveClientFn, deriveClientImpl, deriveClientRL, plainText, toHeaders) as Yoga.Fetch.Om
import Yoga.Format (class ParseTemplate, fmt, format)
import Yoga.Format (fmt, format) as Yoga.Format
import Yoga.Format.Render (class RenderInput)
import Yoga.JSON hiding (read, write) as Yoga.JSON
import Yoga.Om (Om)
import Yoga.Om (Om(..), ParOm(..), delay, error, expand, expandCtx, expandErr, fatal, fromAff, handleErrors, handleErrors', inParallel, launchOm, launchOm_, mapError, note, noteM, onError, parOmToAff, race, readerT, runOm, runOmRecord, runOms, runOmsInOm, runReader, sequenceOmRecord, tap, tapM, throw, throwLeftAs, throwLeftAsM, toOm, unliftAff, unliftAffFn, widenCtx) as Yoga.Om

type CommandResult =
  { code :: Int
  , stdout :: String
  , stderr :: String
  }

type ExecaOptions = Execa.ExecaOptions

type ExecaProcess = Execa.ExecaProcess

type ExecaResult = Execa.ExecaResult

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
    Left err
      | Exception.message err == promptInterruptedMessage -> do
          logError "Interrupted."
          exit 130
      | otherwise -> do
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
runAffWith context script = Yoga.Om.runOm context { exception: Aff.throwError } script

go :: Om {} () Unit -> Effect Unit
go = run

here :: forall ctx err. Om { cwd :: FilePath | ctx } err FilePath
here = asks _.cwd

args :: Effect (Array String)
args = Array.drop 2 <$> Process.argv

cwd :: Effect FilePath
cwd = Process.cwd

lookupEnv :: String -> Effect (Maybe String)
lookupEnv = Process.lookupEnv

env :: forall m. MonadAff m => String -> m String
env = requireEnv

requireEnv :: forall m. MonadAff m => String -> m String
requireEnv name = do
  value <- lookupEnv name # liftEffect
  maybe (failWith $ "Missing environment variable: " <> name) pure value

exit :: Int -> Effect Unit
exit = Process.exit'

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

rm :: forall @args input m. TypedArgs RmGrammarDefinition args input => MonadAff m => input -> m Unit
rm values = x_ "rm" (typedArgs @RmGrammarDefinition @args values)

rm_ :: forall @args m. TypedArgs RmGrammarDefinition args {} => MonadAff m => m Unit
rm_ = x_ "rm" (typedArgs @RmGrammarDefinition @args {})

rmArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
rmArgs = x_ "rm"

mkdir :: forall @args input m. TypedArgs MkdirGrammarDefinition args input => MonadAff m => input -> m Unit
mkdir values = x_ "mkdir" (typedArgs @MkdirGrammarDefinition @args values)

mkdir_ :: forall @args m. TypedArgs MkdirGrammarDefinition args {} => MonadAff m => m Unit
mkdir_ = x_ "mkdir" (typedArgs @MkdirGrammarDefinition @args {})

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

ls :: forall @args input m. TypedArgs LsGrammarDefinition args input => MonadAff m => input -> m String
ls values = x "ls" (typedArgs @LsGrammarDefinition @args values)

ls_ :: forall @args m. TypedArgs LsGrammarDefinition args {} => MonadAff m => m String
ls_ = x "ls" (typedArgs @LsGrammarDefinition @args {})

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

cat :: forall @args input m. TypedArgs CatGrammarDefinition args input => MonadAff m => input -> m String
cat values = x "cat" (typedArgs @CatGrammarDefinition @args values)

cat_ :: forall @args m. TypedArgs CatGrammarDefinition args {} => MonadAff m => m String
cat_ = x "cat" (typedArgs @CatGrammarDefinition @args {})

catArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
catArgs = x "cat"

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
spawn executable commandArgs = spawnWith executable commandArgs identity

spawnWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m ExecaProcess
spawnWith executable commandArgs options = Execa.execa executable (toArgs commandArgs) options # liftAff

spawnPipe :: forall args m. ToArgs args => MonadAff m => String -> args -> m ExecaProcess
spawnPipe executable commandArgs = spawnWith executable commandArgs stream

spawnHere :: forall args ctx err. ToArgs args => String -> args -> Om { cwd :: FilePath | ctx } err ExecaProcess
spawnHere executable commandArgs = do
  dir <- here
  spawnWith executable commandArgs (_ { cwd = Just dir })

execa :: forall args m. ToArgs args => MonadAff m => String -> args -> m ExecaResult
execa executable commandArgs = execaWith executable commandArgs identity

execaWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m ExecaResult
execaWith executable commandArgs options = do
  spawned <- spawnWith executable commandArgs options
  result <- spawned.getResult # liftAff
  ensureOk result

x :: forall args m. ToArgs args => MonadAff m => String -> args -> m String
x executable commandArgs = _.stdout <$> execa executable commandArgs

x_ :: forall args m. ToArgs args => MonadAff m => String -> args -> m Unit
x_ executable commandArgs = void $ execa executable commandArgs

xWith :: forall args m. ToArgs args => MonadAff m => String -> args -> (ExecaOptions -> ExecaOptions) -> m String
xWith executable commandArgs options = _.stdout <$> execaWith executable commandArgs options

xPipe :: forall args m. ToArgs args => MonadAff m => String -> args -> m Unit
xPipe executable commandArgs = void $ execaWith executable commandArgs stream

xHere :: forall args ctx err. ToArgs args => String -> args -> Om { cwd :: FilePath | ctx } err String
xHere executable commandArgs = do
  dir <- here
  xWith executable commandArgs (_ { cwd = Just dir })

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
gum commandArgs = xWith gumBin commandArgs interactive

gum_ :: forall args m. ToArgs args => MonadAff m => args -> m Unit
gum_ commandArgs = void $ execaWith gumBin commandArgs interactive

ensureGum :: forall m. MonadAff m => m Unit
ensureGum = gum_ "--version"

choose :: forall m. MonadAff m => Array String -> m String
choose = chooseNative

chooseNative :: forall m. MonadAff m => Array String -> m String
chooseNative choices = runPrompt $ choosePrompt choices

gumChoose :: forall m. MonadAff m => Array String -> m String
gumChoose choices = gum ([ "choose" ] <> choices)

confirm :: forall m. MonadAff m => String -> m Boolean
confirm = confirmNative

confirmNative :: forall m. MonadAff m => String -> m Boolean
confirmNative message = runPrompt $ confirmPrompt message

gumConfirm :: forall m. MonadAff m => String -> m Boolean
gumConfirm message = do
  spawned <- spawnWith gumBin [ "confirm", message ] interactive
  result <- spawned.getResult # liftAff
  case result.exit of
    Normally 0 -> pure true
    _ -> pure false

input :: forall m. MonadAff m => String -> m String
input = inputNative

inputNative :: forall m. MonadAff m => String -> m String
inputNative placeholder = runPrompt $ inputPrompt placeholder

gumInput :: forall m. MonadAff m => String -> m String
gumInput placeholder = gum [ "input", "--placeholder", placeholder ]

select :: forall m. MonadAff m => Array String -> m String
select choices = runPrompt $ filterPrompt choices

multiSelect :: forall m. MonadAff m => Array String -> m (Array String)
multiSelect choices = runPrompt $ multiSelectPrompt choices

gumFilter :: forall m. MonadAff m => Array String -> m String
gumFilter choices = gum ([ "filter" ] <> choices)

file :: forall m. MonadAff m => FilePath -> m FilePath
file = fileNative

fileNative :: forall m. MonadAff m => FilePath -> m FilePath
fileNative path = do
  entries <- cmd $ "find " <> shellQuote path <> " -maxdepth 2 -mindepth 1 | sort"
  select $ splitLines entries

gumFile :: forall m. MonadAff m => FilePath -> m FilePath
gumFile path = gum [ "file", path ]

pager :: forall m. MonadEffect m => String -> m Unit
pager = pagerNative

pagerNative :: forall m. MonadEffect m => String -> m Unit
pagerNative = Console.log

gumPager :: forall m. MonadAff m => String -> m Unit
gumPager text = void $ cmdWith ("printf %s " <> shellQuote text <> " | gum pager") interactive

table :: forall m. MonadEffect m => Array (Array String) -> m String
table = tableNative

tableNative :: forall m. MonadEffect m => Array (Array String) -> m String
tableNative rows = pure $ renderTable rows

gumTable :: forall m. MonadAff m => Array (Array String) -> m String
gumTable rows = cmdWith ("printf %s " <> shellQuote (toCsv rows) <> " | gum table --print") interactive <#> _.stdout

markdown :: forall m. MonadEffect m => String -> m String
markdown = pure <<< renderMarkdown

gumFormat :: forall m. MonadAff m => String -> m String
gumFormat text = cmdWith ("printf %s " <> shellQuote text <> " | gum format") interactive <#> _.stdout

joinText :: forall m. MonadEffect m => Array String -> m String
joinText = pure <<< String.joinWith "\n"

joinTextHorizontal :: forall m. MonadEffect m => Array String -> m String
joinTextHorizontal = pure <<< String.joinWith " "

gumJoin :: forall m. MonadAff m => Array String -> m String
gumJoin chunks = gum ([ "join" ] <> chunks)

gumLog :: forall m. MonadAff m => Array String -> m Unit
gumLog chunks = gum_ ([ "log" ] <> chunks)

writeNative :: forall m. MonadAff m => String -> m String
writeNative placeholder = runPrompt $ writePrompt placeholder

gumWrite :: forall m. MonadAff m => String -> m String
gumWrite placeholder = gum [ "write", "--placeholder", placeholder ]

spin :: forall m. MonadAff m => String -> String -> m Unit
spin = spinNative

spinNative :: forall m. MonadAff m => String -> String -> m Unit
spinNative title command = do
  _ <- withSpinner title command
  pure unit

gumSpin :: forall m. MonadAff m => String -> String -> m String
gumSpin title command = gum [ "spin", "--title", title, "--", "sh", "-c", command ]

style :: forall m. MonadAff m => String -> String -> m String
style = styleNative

styleNative :: forall m. MonadAff m => String -> String -> m String
styleNative foreground text = pure $ ansiForeground foreground text

data Key
  = KeyChar String
  | KeyEnter
  | KeyEscape
  | KeyBackspace
  | KeyUp
  | KeyDown
  | KeyLeft
  | KeyRight
  | KeyCtrlC
  | KeyCtrlD
  | KeyUnknown String

type Prompt a =
  { render :: Effect (Array String)
  , handle :: Key -> Effect (Maybe a)
  , cancel :: Effect Unit
  , tick :: Boolean
  , redrawFirstLineOnly :: Boolean
  }

runPrompt :: forall m a. MonadAff m => Aff (Prompt a) -> m a
runPrompt build =
  do
    withRawTerminal do
      prompt <- build
      waitForPrompt prompt
    # liftAff

withRawTerminal :: forall a. Aff a -> Aff a
withRawTerminal action = Aff.bracket acquire release use
  where
  acquire = do
    cmd_ "stty raw -echo < /dev/tty"
    writeStderr hideCursorCode # liftEffect

  release _ = do
    writeStderr showCursorCode # liftEffect
    cmd_ "stty sane < /dev/tty"

  use _ = action

waitForPrompt :: forall a. Prompt a -> Aff a
waitForPrompt prompt = Aff.makeAff \finish -> do
  renderedLines <- Ref.new 0
  finished <- Ref.new false
  removeRef <- Ref.new (pure unit :: Effect Unit)
  repaint renderedLines prompt
  Stream.setEncoding Process.stdin UTF8
  repaintInterval <-
    if prompt.tick then Just <$> Timer.setInterval 530 (repaint renderedLines prompt)
    else pure Nothing
  remove <- Process.stdin # on Stream.dataHStr \chunk -> do
    handleKeys finish renderedLines removeRef repaintInterval finished prompt $ decodeKeys chunk
  Ref.write remove removeRef
  Stream.resume Process.stdin
  pure $ Aff.effectCanceler $
    cleanupPrompt renderedLines removeRef repaintInterval finished prompt

handleKeys :: forall a. (Either Exception.Error a -> Effect Unit) -> Ref.Ref Int -> Ref.Ref (Effect Unit) -> Maybe Timer.IntervalId -> Ref.Ref Boolean -> Prompt a -> Array Key -> Effect Unit
handleKeys finish renderedLines removeRef repaintInterval finished prompt keys = do
  done <- Ref.read finished
  if done then pure unit
  else case Array.uncons keys of
    Nothing -> pure unit
    Just { head: KeyCtrlC } ->
      completePrompt finish renderedLines removeRef repaintInterval finished prompt $
        Left promptInterruptedError
    Just { head: key, tail: rest } -> do
      handled <- Exception.try $ prompt.handle key
      case handled of
        Left err ->
          completePrompt finish renderedLines removeRef repaintInterval finished prompt $
            Left err
        Right Nothing -> do
          repaint renderedLines prompt
          handleKeys finish renderedLines removeRef repaintInterval finished prompt rest
        Right (Just value) ->
          completePrompt finish renderedLines removeRef repaintInterval finished prompt $
            Right value

completePrompt :: forall a. (Either Exception.Error a -> Effect Unit) -> Ref.Ref Int -> Ref.Ref (Effect Unit) -> Maybe Timer.IntervalId -> Ref.Ref Boolean -> Prompt a -> Either Exception.Error a -> Effect Unit
completePrompt finish renderedLines removeRef repaintInterval finished prompt result = do
  cleanupPrompt renderedLines removeRef repaintInterval finished prompt
  finish result

cleanupPrompt :: forall a. Ref.Ref Int -> Ref.Ref (Effect Unit) -> Maybe Timer.IntervalId -> Ref.Ref Boolean -> Prompt a -> Effect Unit
cleanupPrompt renderedLines removeRef repaintInterval finished prompt = do
  done <- Ref.read finished
  unless done do
    Ref.write true finished
    join $ Ref.read removeRef
    for_ repaintInterval Timer.clearInterval
    clearPrompt renderedLines
    prompt.cancel
    Stream.pause Process.stdin

repaint :: forall a. Ref.Ref Int -> Prompt a -> Effect Unit
repaint renderedLines prompt = do
  count <- Ref.read renderedLines
  lines <- prompt.render
  if prompt.redrawFirstLineOnly && count == Array.length lines && count > 0 then do
    case Array.head lines of
      Just firstLine -> writeStderr $ redrawFirstLine count firstLine
      Nothing -> pure unit
  else do
    writeStderr $ clearFrame count <> drawFrame lines
    Ref.write (Array.length lines) renderedLines

redrawFirstLine :: Int -> String -> String
redrawFirstLine count line = "\x1b[" <> show count <> "A\x1b[2K\r" <> line <> "\x1b[" <> show count <> "B\r"

clearPrompt :: Ref.Ref Int -> Effect Unit
clearPrompt renderedLines = do
  count <- Ref.read renderedLines
  writeStderr $ clearFrame count
  Ref.write 0 renderedLines

clearFrame :: Int -> String
clearFrame count
  | count <= 0 = ""
  | otherwise = "\x1b[1A" <> Array.foldMap clearLine (Array.range 0 (count - 1))
      where
      clearLine index = "\x1b[2K\r" <> if index < count - 1 then "\x1b[1A" else ""

drawFrame :: Array String -> String
drawFrame = Array.foldMap (_ <> "\r\n")

writeStderr :: String -> Effect Unit
writeStderr text = void $ Stream.writeString Process.stderr UTF8 text

decodeKeys :: String -> Array Key
decodeKeys chunk
  | chunk == "" = []
  | String.CodeUnits.take 3 chunk == "\x1b[A" = [ KeyUp ] <> decodeKeys (String.CodeUnits.drop 3 chunk)
  | String.CodeUnits.take 3 chunk == "\x1b[B" = [ KeyDown ] <> decodeKeys (String.CodeUnits.drop 3 chunk)
  | String.CodeUnits.take 3 chunk == "\x1b[C" = [ KeyRight ] <> decodeKeys (String.CodeUnits.drop 3 chunk)
  | String.CodeUnits.take 3 chunk == "\x1b[D" = [ KeyLeft ] <> decodeKeys (String.CodeUnits.drop 3 chunk)
  | otherwise = case String.CodeUnits.uncons chunk of
      Nothing -> []
      Just { head: char, tail: rest } -> [ decodeChar char ] <> decodeKeys rest

decodeChar :: Char -> Key
decodeChar char = case char of
  '\x03' -> KeyCtrlC
  '\x04' -> KeyCtrlD
  '\x1b' -> KeyEscape
  '\r' -> KeyEnter
  '\n' -> KeyEnter
  '\x7f' -> KeyBackspace
  '\x08' -> KeyBackspace
  _ -> KeyChar $ String.CodeUnits.singleton char

choosePrompt :: Array String -> Aff (Prompt String)
choosePrompt choices = do
  selected <- Ref.new 0 # liftEffect
  pure
    { render: renderChoose selected
    , handle: handleChoose selected
    , cancel: pure unit
    , tick: false
    , redrawFirstLineOnly: false
    }
  where
  height = 10

  renderChoose selected = do
    index <- Ref.read selected
    pure $
      [ purple "Choose:" ]
        <> choiceLines index
        <> [ "", muted "←↓↑→ navigate • enter submit" ]

  handleChoose selected key = do
    case chooseKeyAction key of
      "cancel" -> throwPrompt "nothing selected"
      "submit" -> do
        index <- Ref.read selected
        pure $ Array.index choices index
      "up" -> moveSelected selected (-1)
      "down" -> moveSelected selected 1
      "left" -> moveSelected selected (-height)
      "right" -> moveSelected selected height
      "home" -> Ref.write 0 selected *> pure Nothing
      "end" -> Ref.write (Array.length choices - 1) selected *> pure Nothing
      _ -> pure Nothing

  choiceLines index = do
    let page = Int.quot index height
    let start = page * height
    choices
      # Array.drop start
      # Array.take height
      # Array.mapWithIndex \offset choice -> do
          let actual = start + offset
          if actual == index then pink "> " <> pink choice
          else "  " <> choice

  moveSelected selected delta = do
    index <- Ref.read selected
    let count = Array.length choices
    let next = mod (index + delta + count) count
    Ref.write next selected
    pure Nothing

multiSelectPrompt :: Array String -> Aff (Prompt (Array String))
multiSelectPrompt choices = do
  selected <- Ref.new 0 # liftEffect
  checked <- Ref.new choices # liftEffect
  pure
    { render: renderMultiSelect selected checked
    , handle: handleMultiSelect selected checked
    , cancel: pure unit
    , tick: false
    , redrawFirstLineOnly: false
    }
  where
  height = 10

  renderMultiSelect selected checked = do
    index <- Ref.read selected
    selectedChoices <- Ref.read checked
    pure $
      [ purple "Select:" ]
        <> choiceLines index selectedChoices
        <> [ "", muted "space toggle • a all • n none • ←↓↑→ navigate • enter submit" ]

  handleMultiSelect selected checked key = do
    case multiSelectKeyAction key of
      "cancel" -> throwPrompt "nothing selected"
      "submit" -> Just <$> Ref.read checked
      "toggle" -> do
        index <- Ref.read selected
        case Array.index choices index of
          Nothing -> pure unit
          Just choice -> Ref.modify_ (toggleChoice choice) checked
        pure Nothing
      "all" -> Ref.write choices checked *> pure Nothing
      "none" -> Ref.write [] checked *> pure Nothing
      "up" -> moveSelected selected (-1)
      "down" -> moveSelected selected 1
      "left" -> moveSelected selected (-height)
      "right" -> moveSelected selected height
      "home" -> Ref.write 0 selected *> pure Nothing
      "end" -> Ref.write (Array.length choices - 1) selected *> pure Nothing
      _ -> pure Nothing

  choiceLines index selectedChoices = do
    let page = Int.quot index height
    let start = page * height
    choices
      # Array.drop start
      # Array.take height
      # Array.mapWithIndex \offset choice -> do
          let actual = start + offset
          let mark = if Array.elem choice selectedChoices then "[x] " else "[ ] "
          if actual == index then pink "> " <> pink (mark <> choice)
          else "  " <> mark <> choice

  toggleChoice choice selectedChoices =
    if Array.elem choice selectedChoices then
      Array.filter (_ /= choice) selectedChoices
    else
      selectedChoices <> [ choice ]

  moveSelected selected delta = do
    index <- Ref.read selected
    let count = Array.length choices
    let next = mod (index + delta + count) count
    Ref.write next selected
    pure Nothing

confirmPrompt :: String -> Aff (Prompt Boolean)
confirmPrompt message = do
  yes <- Ref.new true # liftEffect
  pure
    { render: renderConfirm yes
    , handle: handleConfirm yes
    , cancel: pure unit
    , tick: false
    , redrawFirstLineOnly: false
    }
  where
  renderConfirm yes = do
    selected <- Ref.read yes
    pure
      [ bold $ purple $ " " <> message
      , (if selected then selectedButton "Yes" else unselectedButton "Yes") <> " " <> (if selected then unselectedButton "No" else selectedButton "No")
      , ""
      , muted "←→ toggle • enter submit • y Yes • n No"
      ]

  handleConfirm yes key = case confirmKeyAction key of
    "cancel" -> throwPrompt promptInterruptedMessage
    "yes" -> pure $ Just true
    "no" -> pure $ Just false
    "submit" -> Just <$> Ref.read yes
    "toggle" -> Ref.modify_ not yes *> pure Nothing
    _ -> pure Nothing

inputPrompt :: String -> Aff (Prompt String)
inputPrompt placeholder = do
  value <- Ref.new "" # liftEffect
  cursorVisible <- Ref.new true # liftEffect
  interval <- Timer.setInterval 530 (Ref.modify_ not cursorVisible) # liftEffect
  pure
    { render: renderInput value cursorVisible
    , handle: handleInput value cursorVisible
    , cancel: Timer.clearInterval interval
    , tick: true
    , redrawFirstLineOnly: true
    }
  where
  renderInput value cursorVisible = do
    current <- Ref.read value
    visible <- Ref.read cursorVisible
    pure [ "> " <> inputView visible current, "", muted "enter submit" ]

  handleInput value cursorVisible key = do
    Ref.write true cursorVisible
    case textAction key of
      "cancel" -> throwPrompt "not submitted"
      "submit" -> Just <$> Ref.read value
      "backspace" -> Ref.modify_ dropLast value *> pure Nothing
      "ignore" -> pure Nothing
      inserted -> Ref.modify_ (_ <> inserted) value *> pure Nothing

  inputView visible current
    | current == "" = placeholderView visible
    | otherwise = current <> cursorCell " "

  placeholderView visible
    | placeholder == "" = if visible then cursorCell " " else " "
    | visible = selectedPlaceholder placeholder
    | otherwise = muted placeholder

writePrompt :: String -> Aff (Prompt String)
writePrompt placeholder = do
  linesRef <- Ref.new ([] :: Array String) # liftEffect
  currentRef <- Ref.new "" # liftEffect
  pure
    { render: renderWrite linesRef currentRef
    , handle: handleWrite linesRef currentRef
    , cancel: pure unit
    , tick: false
    , redrawFirstLineOnly: false
    }
  where
  renderWrite linesRef currentRef = do
    lines <- Ref.read linesRef
    current <- Ref.read currentRef
    let visible = Array.drop (max 0 (Array.length lines - 8)) lines
    pure $
      [ purple "Write:" ]
        <> (visible <#> ("  " <> _))
        <> [ "> " <> writeCurrent current, "", muted "enter newline • ctrl+d submit • esc cancel" ]

  handleWrite linesRef currentRef = case _ of
    KeyCtrlC -> throwPrompt "not submitted"
    KeyEscape -> throwPrompt "not submitted"
    KeyCtrlD -> do
      lines <- Ref.read linesRef
      current <- Ref.read currentRef
      pure $ Just $ String.joinWith "\n" $ lines <> [ current ]
    KeyEnter -> do
      current <- Ref.read currentRef
      Ref.modify_ (_ <> [ current ]) linesRef
      Ref.write "" currentRef
      pure Nothing
    KeyBackspace -> Ref.modify_ dropLast currentRef *> pure Nothing
    KeyChar inserted -> Ref.modify_ (_ <> inserted) currentRef *> pure Nothing
    _ -> pure Nothing

  writeCurrent current
    | current == "" = muted placeholder <> cursorCell " "
    | otherwise = current <> cursorCell " "

filterPrompt :: Array String -> Aff (Prompt String)
filterPrompt choices = do
  queryRef <- Ref.new "" # liftEffect
  selected <- Ref.new 0 # liftEffect
  focused <- Ref.new true # liftEffect
  height <- filterViewportHeight
  pure
    { render: renderFilter height queryRef selected focused
    , handle: handleFilter queryRef selected focused
    , cancel: pure unit
    , tick: false
    , redrawFirstLineOnly: false
    }
  where
  renderFilter height queryRef selected focused = do
    query <- Ref.read queryRef
    index <- Ref.read selected
    isFocused <- Ref.read focused
    let matched = matches query
    if index >= Array.length matched then Ref.write (max 0 (Array.length matched - 1)) selected
    else pure unit
    pure $
      [ "> " <> if query == "" then muted "Filter..." else query ]
        <> filterLines height query index matched
        <> [ "", filterHelp isFocused ]

  handleFilter queryRef selected focused key = do
    isFocused <- Ref.read focused
    if isFocused then handleFocused queryRef selected focused key
    else handleBlurred queryRef selected focused key

  handleFocused queryRef selected focused key = do
    action <- pure $ textAction key
    case action of
      "cancel" -> Ref.write false focused *> pure Nothing
      "submit" -> submitFilter queryRef selected
      "up" -> cursorUp selected *> pure Nothing
      "down" -> cursorDown queryRef selected *> pure Nothing
      "backspace" -> Ref.modify_ dropLast queryRef *> Ref.write 0 selected *> pure Nothing
      "ignore" -> pure Nothing
      inserted -> Ref.modify_ (_ <> inserted) queryRef *> Ref.write 0 selected *> pure Nothing

  handleBlurred queryRef selected focused key = do
    case filterNavigationAction key of
      "cancel" -> throwPrompt "nothing selected"
      "focus" -> Ref.write true focused *> pure Nothing
      "submit" -> submitFilter queryRef selected
      "up" -> cursorUp selected *> pure Nothing
      "down" -> cursorDown queryRef selected *> pure Nothing
      "home" -> Ref.write 0 selected *> pure Nothing
      "end" -> do
        query <- Ref.read queryRef
        Ref.write (Array.length (matches query) - 1) selected
        pure Nothing
      _ -> pure Nothing

  submitFilter queryRef selected = do
    query <- Ref.read queryRef
    index <- Ref.read selected
    pure $ Array.index (matches query) index

  cursorUp selected = Ref.modify_ (max 0 <<< (_ - 1)) selected

  cursorDown queryRef selected = do
    query <- Ref.read queryRef
    Ref.modify_ (min (Array.length (matches query) - 1) <<< (_ + 1)) selected

  filterLines height query index matched = case Array.take height matched of
    [] -> [ "  " <> muted "No matches" ]
    visible -> visible # Array.mapWithIndex \offset choice ->
      if offset == index then pink "•" <> " " <> highlightMatch query choice
      else "  " <> highlightMatch query choice

  filterHelp focused
    | focused = muted "↓↑ navigate • esc blur search • enter submit"
    | otherwise = muted "↓↑ navigate • / search • esc quit • enter submit"

  matches query = choices # Array.filter (fuzzyMatch query)

withSpinner :: forall m. MonadAff m => String -> String -> m String
withSpinner title command = do
  liftAff do
    resultRef <- Ref.new Nothing # liftEffect
    _ <- Aff.forkAff do
      result <- Aff.try $ cmd command
      Ref.write (Just result) resultRef # liftEffect
    spinUntilDone title 0 resultRef

spinUntilDone :: String -> Int -> Ref.Ref (Maybe (Either Exception.Error String)) -> Aff String
spinUntilDone title index resultRef = do
  result <- Ref.read resultRef # liftEffect
  case result of
    Nothing -> do
      writeStderr ("\r\x1b[2K" <> pink (spinnerFrame index) <> " " <> title) # liftEffect
      Aff.delay $ Milliseconds 80.0
      spinUntilDone title (index + 1) resultRef
    Just (Left err) -> do
      writeStderr ("\r\x1b[2K✗ " <> title <> "\n") # liftEffect
      Aff.throwError err
    Just (Right value) -> do
      writeStderr ("\r\x1b[2K" <> pink "✓" <> " " <> title <> "\n") # liftEffect
      pure value

splitLines :: String -> Array String
splitLines text = String.split (Pattern "\n") (String.trim text) # Array.filter (_ /= "")

shellQuote :: String -> String
shellQuote text = "'" <> Regex.replace (unsafeRegex "'" noFlags) "'\\''" text <> "'"

toCsv :: Array (Array String) -> String
toCsv rows = String.joinWith "\n" $ rows <#> String.joinWith ","

renderTable :: Array (Array String) -> String
renderTable rows = do
  let widths = columnWidths rows
  rows
    <#> renderTableRow widths
    # String.joinWith "\n"

renderTableRow :: Array Int -> Array String -> String
renderTableRow widths row = do
  let padded = row # Array.mapWithIndex \index cell -> padRight (maybe 0 identity $ Array.index widths index) cell
  String.joinWith "  " padded

columnWidths :: Array (Array String) -> Array Int
columnWidths rows = do
  let count = Array.foldl max 0 $ rows <#> Array.length
  Array.range 0 (count - 1) <#> \index -> do
    let cells = rows <#> \row -> maybe "" identity $ Array.index row index
    Array.foldl (\longest cell -> max longest $ String.CodeUnits.length cell) 0 cells

renderMarkdown :: String -> String
renderMarkdown text = do
  let lines = String.split (Pattern "\n") text <#> renderMarkdownLine
  String.joinWith "\n" lines

renderMarkdownLine :: String -> String
renderMarkdownLine line
  | String.CodeUnits.take 2 line == "# " = bold $ purple $ String.CodeUnits.drop 2 line
  | String.CodeUnits.take 3 line == "## " = bold $ pink $ String.CodeUnits.drop 3 line
  | String.CodeUnits.take 2 line == "- " = pink "• " <> String.CodeUnits.drop 2 line
  | otherwise = line

padRight :: Int -> String -> String
padRight width text = text <> String.CodeUnits.fromCharArray (Array.replicate (max 0 $ width - String.CodeUnits.length text) ' ')

filterViewportHeight :: Aff Int
filterViewportHeight = do
  rows <- cmd "stty size < /dev/tty | awk '{ print $1 }'"
  pure case Int.fromString (String.trim rows) of
    Just count -> max 1 (count - 5)
    Nothing -> 10

spinnerFrame :: Int -> String
spinnerFrame index = case Array.index [ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" ] (mod index 10) of
  Just frame -> frame
  Nothing -> "⠋"

chooseKeyAction :: Key -> String
chooseKeyAction = case _ of
  KeyCtrlC -> "cancel"
  KeyEscape -> "cancel"
  KeyEnter -> "submit"
  KeyUp -> "up"
  KeyDown -> "down"
  KeyLeft -> "left"
  KeyRight -> "right"
  KeyChar "k" -> "up"
  KeyChar "j" -> "down"
  KeyChar "h" -> "left"
  KeyChar "l" -> "right"
  KeyChar "g" -> "home"
  KeyChar "G" -> "end"
  _ -> "ignore"

multiSelectKeyAction :: Key -> String
multiSelectKeyAction = case _ of
  KeyCtrlC -> "cancel"
  KeyEscape -> "cancel"
  KeyEnter -> "submit"
  KeyUp -> "up"
  KeyDown -> "down"
  KeyLeft -> "left"
  KeyRight -> "right"
  KeyChar " " -> "toggle"
  KeyChar "k" -> "up"
  KeyChar "j" -> "down"
  KeyChar "h" -> "left"
  KeyChar "l" -> "right"
  KeyChar "g" -> "home"
  KeyChar "G" -> "end"
  KeyChar "a" -> "all"
  KeyChar "A" -> "all"
  KeyChar "n" -> "none"
  KeyChar "N" -> "none"
  _ -> "ignore"

confirmKeyAction :: Key -> String
confirmKeyAction = case _ of
  KeyCtrlC -> "cancel"
  KeyEscape -> "no"
  KeyEnter -> "submit"
  KeyLeft -> "toggle"
  KeyRight -> "toggle"
  KeyChar "h" -> "toggle"
  KeyChar "l" -> "toggle"
  KeyChar "y" -> "yes"
  KeyChar "Y" -> "yes"
  KeyChar "n" -> "no"
  KeyChar "N" -> "no"
  KeyChar "q" -> "no"
  _ -> "ignore"

textAction :: Key -> String
textAction = case _ of
  KeyCtrlC -> "cancel"
  KeyEscape -> "cancel"
  KeyEnter -> "submit"
  KeyBackspace -> "backspace"
  KeyUp -> "up"
  KeyDown -> "down"
  KeyChar char -> char
  _ -> "ignore"

filterNavigationAction :: Key -> String
filterNavigationAction = case _ of
  KeyCtrlC -> "cancel"
  KeyEscape -> "cancel"
  KeyEnter -> "submit"
  KeyUp -> "up"
  KeyDown -> "down"
  KeyChar "k" -> "up"
  KeyChar "j" -> "down"
  KeyChar "g" -> "home"
  KeyChar "G" -> "end"
  KeyChar "/" -> "focus"
  _ -> "ignore"

fuzzyMatch :: String -> String -> Boolean
fuzzyMatch query value = fuzzyMatchFrom (String.CodeUnits.toCharArray $ String.toLower query) (String.CodeUnits.toCharArray $ String.toLower value)

fuzzyMatchFrom :: Array Char -> Array Char -> Boolean
fuzzyMatchFrom query value = case Array.uncons query of
  Nothing -> true
  Just { head: wanted, tail: rest } -> case Array.findIndex (_ == wanted) value of
    Nothing -> false
    Just index -> fuzzyMatchFrom rest $ Array.drop (index + 1) value

highlightMatch :: String -> String -> String
highlightMatch query value = highlightMatchFrom (String.CodeUnits.toCharArray $ String.toLower query) (String.CodeUnits.toCharArray value)

highlightMatchFrom :: Array Char -> Array Char -> String
highlightMatchFrom query value = case Array.uncons value of
  Nothing -> ""
  Just { head: char, tail: rest } -> case Array.uncons query of
    Nothing -> String.CodeUnits.singleton char <> charsToString rest
    Just { head: wanted, tail: remaining } ->
      if String.toLower (String.CodeUnits.singleton char) == String.CodeUnits.singleton wanted then pink (String.CodeUnits.singleton char) <> highlightMatchFrom remaining rest
      else String.CodeUnits.singleton char <> highlightMatchFrom query rest

charsToString :: Array Char -> String
charsToString = Array.foldMap String.CodeUnits.singleton

dropLast :: String -> String
dropLast text = String.CodeUnits.take (String.CodeUnits.length text - 1) text

selectedPlaceholder :: String -> String
selectedPlaceholder text = do
  let first = String.CodeUnits.take 1 text
  let rest = String.CodeUnits.drop 1 text
  placeholderCursorCell first <> muted rest

cursorCell :: String -> String
cursorCell text = bg "212" $ cream text

placeholderCursorCell :: String -> String
placeholderCursorCell text = bg "212" $ muted text

promptInterruptedMessage :: String
promptInterruptedMessage = "__spago_script_prompt_interrupted__"

promptInterruptedError :: Exception.Error
promptInterruptedError = Exception.error promptInterruptedMessage

throwPrompt :: forall a. String -> Effect (Maybe a)
throwPrompt message = Exception.throw message

ansiForeground :: String -> String -> String
ansiForeground foreground text = "\x1b[38;5;" <> foreground <> "m" <> text <> "\x1b[0m"

ansi :: String -> String -> String
ansi code text = "\x1b[" <> code <> "m" <> text <> "\x1b[0m"

fg :: String -> String -> String
fg color = ansi $ "38;5;" <> color

bg :: String -> String -> String
bg color = ansi $ "48;5;" <> color

pink :: String -> String
pink = fg "212"

purple :: String -> String
purple = fg "99"

muted :: String -> String
muted = fg "240"

cream :: String -> String
cream = fg "230"

bold :: String -> String
bold = ansi "1"

selectedButton :: String -> String
selectedButton text = bg "212" $ cream $ "   " <> text <> "   "

unselectedButton :: String -> String
unselectedButton text = bg "235" $ fg "254" $ "   " <> text <> "   "

hideCursorCode :: String
hideCursorCode = "\x1b[?25l"

showCursorCode :: String
showCursorCode = "\x1b[?25h"

gumBin :: String
gumBin = "gum"

interactive :: ExecaOptions -> ExecaOptions
interactive options = options
  { stdin = Just inherit
  , stderr = Just inherit
  }

stream :: ExecaOptions -> ExecaOptions
stream options = options
  { stdin = Just inherit
  , stdout = Just inherit
  , stderr = Just inherit
  }

mv :: forall @args input m. TypedArgs MvGrammarDefinition args input => MonadAff m => input -> m Unit
mv values = x_ "mv" (typedArgs @MvGrammarDefinition @args values)

mv_ :: forall @args m. TypedArgs MvGrammarDefinition args {} => MonadAff m => m Unit
mv_ = x_ "mv" (typedArgs @MvGrammarDefinition @args {})

mvArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
mvArgs = x_ "mv"

cp :: forall @args input m. TypedArgs CpGrammarDefinition args input => MonadAff m => input -> m Unit
cp values = x_ "cp" (typedArgs @CpGrammarDefinition @args values)

cp_ :: forall @args m. TypedArgs CpGrammarDefinition args {} => MonadAff m => m Unit
cp_ = x_ "cp" (typedArgs @CpGrammarDefinition @args {})

cpArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
cpArgs = x_ "cp"

git :: forall @args input m. TypedArgs GitGrammarDefinition args input => MonadAff m => input -> m String
git values = x "git" (typedArgs @GitGrammarDefinition @args values)

git_ :: forall @args m. TypedArgs GitGrammarDefinition args {} => MonadAff m => m String
git_ = x "git" (typedArgs @GitGrammarDefinition @args {})

gitArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
gitArgs = x "git"

spago :: forall @args input m. TypedArgs SpagoGrammarDefinition args input => MonadAff m => input -> m String
spago values = x "spago" (typedArgs @SpagoGrammarDefinition @args values)

spago_ :: forall @args m. TypedArgs SpagoGrammarDefinition args {} => MonadAff m => m String
spago_ = x "spago" (typedArgs @SpagoGrammarDefinition @args {})

spagoArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
spagoArgs = x "spago"

grep :: forall @args input m. TypedArgs GrepGrammarDefinition args input => MonadAff m => input -> m String
grep values = x "grep" (typedArgs @GrepGrammarDefinition @args values)

grep_ :: forall @args m. TypedArgs GrepGrammarDefinition args {} => MonadAff m => m String
grep_ = x "grep" (typedArgs @GrepGrammarDefinition @args {})

grepArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
grepArgs = x "grep"

find :: forall @args input m. TypedArgs FindGrammarDefinition args input => MonadAff m => input -> m String
find values = x "find" (typedArgs @FindGrammarDefinition @args values)

find_ :: forall @args m. TypedArgs FindGrammarDefinition args {} => MonadAff m => m String
find_ = x "find" (typedArgs @FindGrammarDefinition @args {})

findArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
findArgs = x "find"

sort :: forall @args input m. TypedArgs SortGrammarDefinition args input => MonadAff m => input -> m String
sort values = x "sort" (typedArgs @SortGrammarDefinition @args values)

sort_ :: forall @args m. TypedArgs SortGrammarDefinition args {} => MonadAff m => m String
sort_ = x "sort" (typedArgs @SortGrammarDefinition @args {})

sortArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
sortArgs = x "sort"

uniq :: forall @args input m. TypedArgs UniqGrammarDefinition args input => MonadAff m => input -> m String
uniq values = x "uniq" (typedArgs @UniqGrammarDefinition @args values)

uniq_ :: forall @args m. TypedArgs UniqGrammarDefinition args {} => MonadAff m => m String
uniq_ = x "uniq" (typedArgs @UniqGrammarDefinition @args {})

uniqArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
uniqArgs = x "uniq"

rg :: forall @args input m. TypedArgs RgGrammarDefinition args input => MonadAff m => input -> m String
rg values = x "rg" (typedArgs @RgGrammarDefinition @args values)

rg_ :: forall @args m. TypedArgs RgGrammarDefinition args {} => MonadAff m => m String
rg_ = x "rg" (typedArgs @RgGrammarDefinition @args {})

rgArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
rgArgs = x "rg"

jj :: forall @args input m. TypedArgs JjGrammarDefinition args input => MonadAff m => input -> m String
jj values = x "jj" (typedArgs @JjGrammarDefinition @args values)

jj_ :: forall @args m. TypedArgs JjGrammarDefinition args {} => MonadAff m => m String
jj_ = x "jj" (typedArgs @JjGrammarDefinition @args {})

jjArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
jjArgs = x "jj"

gh :: forall @args input m. TypedArgs GhGrammarDefinition args input => MonadAff m => input -> m String
gh values = x "gh" (typedArgs @GhGrammarDefinition @args values)

gh_ :: forall @args m. TypedArgs GhGrammarDefinition args {} => MonadAff m => m String
gh_ = x "gh" (typedArgs @GhGrammarDefinition @args {})

ghArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
ghArgs = x "gh"

purs :: forall @args input m. TypedArgs PursGrammarDefinition args input => MonadAff m => input -> m String
purs values = x "purs" (typedArgs @PursGrammarDefinition @args values)

purs_ :: forall @args m. TypedArgs PursGrammarDefinition args {} => MonadAff m => m String
purs_ = x "purs" (typedArgs @PursGrammarDefinition @args {})

pursArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
pursArgs = x "purs"

pursTidy :: forall @args input m. TypedArgs PursTidyGrammarDefinition args input => MonadAff m => input -> m String
pursTidy values = x "purs-tidy" (typedArgs @PursTidyGrammarDefinition @args values)

pursTidy_ :: forall @args m. TypedArgs PursTidyGrammarDefinition args {} => MonadAff m => m String
pursTidy_ = x "purs-tidy" (typedArgs @PursTidyGrammarDefinition @args {})

pursTidyArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
pursTidyArgs = x "purs-tidy"

sed :: forall @args input m. TypedArgs SedGrammarDefinition args input => MonadAff m => input -> m String
sed values = x "sed" (typedArgs @SedGrammarDefinition @args values)

sed_ :: forall @args m. TypedArgs SedGrammarDefinition args {} => MonadAff m => m String
sed_ = x "sed" (typedArgs @SedGrammarDefinition @args {})

sedArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
sedArgs = x "sed"

head :: forall @args input m. TypedArgs HeadGrammarDefinition args input => MonadAff m => input -> m String
head values = x "head" (typedArgs @HeadGrammarDefinition @args values)

head_ :: forall @args m. TypedArgs HeadGrammarDefinition args {} => MonadAff m => m String
head_ = x "head" (typedArgs @HeadGrammarDefinition @args {})

headArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
headArgs = x "head"

tail :: forall @args input m. TypedArgs TailGrammarDefinition args input => MonadAff m => input -> m String
tail values = x "tail" (typedArgs @TailGrammarDefinition @args values)

tail_ :: forall @args m. TypedArgs TailGrammarDefinition args {} => MonadAff m => m String
tail_ = x "tail" (typedArgs @TailGrammarDefinition @args {})

tailArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
tailArgs = x "tail"

wc :: forall @args input m. TypedArgs WcGrammarDefinition args input => MonadAff m => input -> m String
wc values = x "wc" (typedArgs @WcGrammarDefinition @args values)

wc_ :: forall @args m. TypedArgs WcGrammarDefinition args {} => MonadAff m => m String
wc_ = x "wc" (typedArgs @WcGrammarDefinition @args {})

wcArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
wcArgs = x "wc"

tee :: forall @args input m. TypedArgs TeeGrammarDefinition args input => MonadAff m => input -> m String
tee values = x "tee" (typedArgs @TeeGrammarDefinition @args values)

tee_ :: forall @args m. TypedArgs TeeGrammarDefinition args {} => MonadAff m => m String
tee_ = x "tee" (typedArgs @TeeGrammarDefinition @args {})

teeArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
teeArgs = x "tee"

touch :: forall @args input m. TypedArgs TouchGrammarDefinition args input => MonadAff m => input -> m Unit
touch values = x_ "touch" (typedArgs @TouchGrammarDefinition @args values)

touch_ :: forall @args m. TypedArgs TouchGrammarDefinition args {} => MonadAff m => m Unit
touch_ = x_ "touch" (typedArgs @TouchGrammarDefinition @args {})

touchArgs :: forall args m. ToArgs args => MonadAff m => args -> m Unit
touchArgs = x_ "touch"

which :: forall @args input m. TypedArgs WhichGrammarDefinition args input => MonadAff m => input -> m String
which values = x "which" (typedArgs @WhichGrammarDefinition @args values)

which_ :: forall @args m. TypedArgs WhichGrammarDefinition args {} => MonadAff m => m String
which_ = x "which" (typedArgs @WhichGrammarDefinition @args {})

whichArgs :: forall args m. ToArgs args => MonadAff m => args -> m String
whichArgs = x "which"

infixl 1 pipeInto as |>

class PipeTarget target where
  pipeTarget :: forall m. MonadAff m => String -> target -> m String

instance PipeTarget String where
  pipeTarget = pipeShell

instance PipeTarget CommandInvocation where
  pipeTarget stdin (CommandInvocation { executable, arguments }) = pipeProcess stdin executable arguments

pipeInto :: forall target m. PipeTarget target => MonadAff m => m String -> target -> m String
pipeInto source target = do
  stdin <- source
  pipeTarget stdin target

infixr 1 pipeFrom as <|

pipeFrom :: forall target m. PipeTarget target => MonadAff m => target -> m String -> m String
pipeFrom target source = source |> target

pipeShell :: forall m. MonadAff m => String -> String -> m String
pipeShell stdin command = pipeProcess stdin shell [ "-c", command ]
  where
  shell = "sh"

pipeProcess :: forall m. MonadAff m => String -> String -> Array String -> m String
pipeProcess stdin executable arguments = do
  spawned <- spawnWith executable arguments (_ { stdin = Just ChildProcess.pipe })
  case spawned.stdin of
    Just childStdin -> childStdin.writeUtf8End stdin # liftAff
    Nothing -> failWith $ "Could not open stdin for command: " <> executable
  result <- spawned.getResult # liftAff
  _.stdout <$> ensureOk result
  where
  shell = "sh"

exec :: forall m. MonadAff m => String -> Array String -> m CommandResult
exec command commandArgs = do
  spawned <- spawnWith command commandArgs (_ { stripFinalNewline = Just false })
  result <- spawned.getResult # liftAff
  pure
    { code: exitCode result.exit
    , stdout: result.stdout
    , stderr: result.stderr
    }
  where
  exitCode = case _ of
    Normally code -> code
    BySignal _ -> 1

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
