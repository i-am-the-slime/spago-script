module Test.Main where

import Script.Prelude

import Data.Either (either)
import Data.Identity (Identity(..))
import Data.Newtype (un)
import Data.String.CodeUnits as String.CodeUnits
import Effect.Aff (Aff, attempt, bracket)
import Effect.Exception (message, throwException)
import Effect.Exception as Exception
import Foreign.Object as Object
import Go.Net.HTTP (Address(..), HeaderName(..), HeaderValue(..), Path(..), Status(..))
import Go.Net.HTTP as HTTP
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (defaultConfig, evalSpecT)
import Test.Spec.Summary (successful)

main :: Effect Unit
main = launch do
  results <- un Identity (evalSpecT (defaultConfig { exit = false }) [ consoleReporter ] specs)
  unless (successful results) (exit 1 # liftEffect)

specs :: Spec Unit
specs = describe "Script.Prelude on Go" do
  files
  processes
  commands
  pipes
  formatting
  jsonSpec
  sqlite
  fetching
  cookies

files :: Spec Unit
files = describe "files" do
  it "reads, writes, appends, and checks files" do
    mkdirp testDirectory
    writeTextFile testFile "hello"
    appendTextFile testFile " script"
    contents <- readTextFile testFile
    fileThere <- fileExists testFile
    dirThere <- directoryExists testDirectory
    contents `shouldEqual` "hello script"
    fileThere `shouldEqual` true
    dirThere `shouldEqual` true
    removeFile testFile
    gone <- fileExists testFile
    gone `shouldEqual` false

  it "lists directories" do
    removeDir testDirectory
    mkdirp testDirectory
    writeTextFile testFile "listed"
    entries <- listDir testDirectory
    entries `shouldEqual` [ "prelude.txt" ]

  it "copies, renames, links and resolves files" do
    write (testDirectory / "a.txt") "copied"
    copy (testDirectory / "a.txt") (testDirectory / "b.txt")
    rename (testDirectory / "b.txt") (testDirectory / "c.txt")
    symlink "c.txt" (testDirectory / "link") FileLink
    target <- readlink (testDirectory / "link")
    resolved <- realpath (testDirectory / "link")
    linked <- read (testDirectory / "link")
    target `shouldEqual` "c.txt"
    linked `shouldEqual` "copied"
    String.CodeUnits.takeRight 5 resolved `shouldEqual` "c.txt"
    truncate (testDirectory / "c.txt") 4
    read (testDirectory / "c.txt") >>= shouldEqual "copi"

  it "fails with the path when a file is missing" do
    result <- attempt $ read (testDirectory / "missing.txt")
    either message (const "read it") result `shouldEqual` ("no such file or directory: " <> (testDirectory / "missing.txt"))

  it "makes temporary directories with a prefix" do
    temporary <- mkdtemp (testDirectory / "temp-")
    isTemporaryDir <- isDir temporary
    String.CodeUnits.take (String.CodeUnits.length (testDirectory / "temp-")) temporary `shouldEqual` (testDirectory / "temp-")
    isTemporaryDir `shouldEqual` true

  it "removes files that aren't there without complaint" do
    removeFile (testDirectory / "never-there.txt")
    removeDir (testDirectory / "never-there")

processes :: Spec Unit
processes = describe "processes" do
  it "reads process information" do
    workingDirectory <- cwd # liftEffect
    scriptArgs <- args # liftEffect
    missing <- lookupEnv "SPAGO_SCRIPT_PRELUDE_MISSING_FOR_TEST" # liftEffect
    (workingDirectory == "") `shouldEqual` false
    scriptArgs `shouldEqual` []
    missing `shouldEqual` Nothing

  it "fails on a missing environment variable" do
    result <- attempt $ env "SPAGO_SCRIPT_PRELUDE_MISSING_FOR_TEST"
    either message identity result `shouldEqual` "Missing environment variable: SPAGO_SCRIPT_PRELUDE_MISSING_FOR_TEST"

  it "runs commands and shell snippets" do
    result <- exec "sh" [ "-c", "echo ok" ]
    output <- sh "printf shell"
    result.code `shouldEqual` 0
    result.stdout `shouldEqual` "ok\n"
    output `shouldEqual` "shell"

  it "runs filesystem scripts in Om" do
    contents <- runAff do
      mkdirp testDirectory
      write testFile "om"
      read testFile
    contents `shouldEqual` "om"

  it "runs execa helpers and strips the final newline" do
    output <- x "echo" [ "execa" ]
    commandOutput <- cmd "printf command"
    splitOutput <- x "echo" "split on spaces"
    output `shouldEqual` "execa"
    commandOutput `shouldEqual` "command"
    splitOutput `shouldEqual` "split on spaces"

  it "uses reader cwd for execa helpers" do
    output <- runAffWith { cwd: testDirectory } do
      mkdirp testDirectory
      write (testDirectory / "cwd.txt") "from reader"
      cmdHere "cat cwd.txt"
    output `shouldEqual` "from reader"

  it "passes extra environment variables" do
    output <- xWith "sh" [ "-c", "echo $GREETING" ] (_ { env = Just (Object.singleton "GREETING" "moin") })
    output `shouldEqual` "moin"

  it "fails like execa when a command fails" do
    result <- attempt $ x "sh" [ "-c", "echo oops >&2; exit 3" ]
    either message identity result `shouldEqual` "Command failed with exit code 3: sh -c \"echo oops >&2; exit 3\"\noops"

  it "fails when a program doesn't exist" do
    result <- attempt $ x "no-such-program-anywhere" ([] :: Array String)
    either message identity result `shouldEqual` "Command failed with ENOENT: no-such-program-anywhere\nspawn no-such-program-anywhere ENOENT"

  it "spawns a program and kills it" do
    process <- spawn "sleep" [ "10" ]
    killed <- process.kill
    result <- process.getResult
    killed `shouldEqual` true
    result.exit `shouldEqual` BySignal (KillSignal "SIGKILL")
    result.exitCode `shouldEqual` Nothing

commands :: Spec Unit
commands = describe "typed commands" do
  it "runs command aliases" do
    removeDir testDirectory
    mkdirp testDirectory
    write (testDirectory / "pipe.txt") "pipe"
    write (testDirectory / "cwd.txt") "cwd"
    listed <- ls_ @"output/script-prelude-test"
    listedWithArgs <- lsArgs [ testDirectory ]
    listedWithFlatArgs <- lsArgs ("-1 " <> testDirectory)
    listedWithTemplate <- ls @"-1 $dir" { dir: testDirectory }
    listed `shouldEqual` "cwd.txt\npipe.txt"
    listedWithArgs `shouldEqual` "cwd.txt\npipe.txt"
    listedWithFlatArgs `shouldEqual` "cwd.txt\npipe.txt"
    listedWithTemplate `shouldEqual` "cwd.txt\npipe.txt"

  it "runs typed command templates" do
    mkdir @"-p $dir" { dir: testDirectory / "commands" }
    write (testDirectory / "commands" / "a.txt") "commands"
    cp @"$from $to" { from: testDirectory / "commands" / "a.txt", to: testDirectory / "commands" / "b.txt" }
    mv @"$from $to" { from: testDirectory / "commands" / "b.txt", to: testDirectory / "commands" / "c.txt" }
    found <- grep @"commands $file" { file: testDirectory / "commands" / "c.txt" }
    rm @"-f $file" { file: testDirectory / "commands" / "c.txt" }
    lineCount <- wc @"-l $file" { file: testDirectory / "commands" / "a.txt" }
    shell <- which_ @"sh"
    found `shouldEqual` "commands"
    (lineCount == "") `shouldEqual` false
    (shell == "") `shouldEqual` false

  it "keeps quoted arguments together" do
    write (testDirectory / "names with spaces.txt") "Ada\nGrace\nAlan\n"
    firstTwo <- head @"-n $count $file" { count: 2, file: testDirectory / "names with spaces.txt" }
    firstTwo `shouldEqual` "Ada\nGrace"

pipes :: Spec Unit
pipes = describe "pipes" do
  it "pipes output into shell commands" do
    piped <- x "printf" [ "one\ntwo\n" ] |> "grep two"
    pipedBackwards <- "grep one" <| x "printf" [ "one\ntwo\n" ]
    piped `shouldEqual` "two"
    pipedBackwards `shouldEqual` "one"

  it "pipes output into typed commands" do
    write (testDirectory / "names.txt") "Ada\nGrace\nAlan\n"
    matched <- cat @"$file" { file: testDirectory / "names.txt" }
      |> typedCommand @GrepGrammarDefinition @"$pattern" { pattern: "Grace" }
    matched `shouldEqual` "Grace"

formatting :: Spec Unit
formatting = describe "formatting" do
  it "formats strings" do
    fmt @"hello $name" { name: "scripts" } `shouldEqual` "hello scripts"
    logFmt @"hello $name" { name: "scripts" }

  it "renders gum-style pure helpers" do
    joined <- joinText [ "alpha", "beta" ]
    horizontal <- joinTextHorizontal [ "alpha", "beta" ]
    renderedTable <- table [ [ "name", "kind" ], [ "demo", "app" ] ]
    formatted <- markdown "# Title\n- item"
    styled <- style "212" "pink"
    joined `shouldEqual` "alpha\nbeta"
    horizontal `shouldEqual` "alpha beta"
    renderedTable `shouldEqual` "name  kind\ndemo  app "
    formatted `shouldEqual` "\x1b[1m\x1b[38;5;99mTitle\x1b[0m\x1b[0m\n\x1b[38;5;212m• \x1b[0mitem"
    styled `shouldEqual` "\x1b[38;5;212mpink\x1b[0m"

  it "joins paths" do
    ("src" / "Main.purs") `shouldEqual` "src/Main.purs"
    ("src/" / "../Main.purs") `shouldEqual` "Main.purs"

jsonSpec :: Spec Unit
jsonSpec = describe "JSON" do
  it "reads and writes JSON from yoga-json" do
    let encoded = writeJSON { name: "scripts", count: 2 }
    let decoded = readJSON_ @{ name :: String, count :: Int } encoded
    decoded `shouldEqual` Just { name: "scripts", count: 2 }

sqlite :: Spec Unit
sqlite = describe "SQLite" do
  it "queries one text value" do
    answer <- querySQLiteText (SQLitePath ":memory:") (SQLiteQuery "select 'from sqlite'")
    answer `shouldEqual` "from sqlite"

  it "fails on a query without rows" do
    result <- attempt $ querySQLiteText (SQLitePath ":memory:") (SQLiteQuery "select 'x' where 1 = 0")
    either message identity result `shouldEqual` "SQLite query returned no row"

  it "fails on more than one column" do
    result <- attempt $ querySQLiteText (SQLitePath ":memory:") (SQLiteQuery "select 'a', 'b'")
    either message identity result `shouldEqual` "SQLite query must return exactly one text column"

  it "opens files read-only" do
    _ <- x "rm" [ "-f", testDirectory / "test.db" ]
    created <- exec "sqlite3" [ testDirectory / "test.db", "create table t (name text); insert into t values ('Ada');" ]
    when (created.code == 0) do
      name <- querySQLiteText (SQLitePath (testDirectory / "test.db")) (SQLiteQuery "select name from t")
      written <- attempt $ querySQLiteText (SQLitePath (testDirectory / "test.db")) (SQLiteQuery "insert into t values ('Grace') returning name")
      name `shouldEqual` "Ada"
      either (const "refused") identity written `shouldEqual` "refused"

fetching :: Spec Unit
fetching = describe "fetch" do
  it "fetches text with a method, headers and a body" do
    withServer \base -> do
      response <- fetch (URL (base <> "/echo")) { method: postMethod, headers: makeHeaders { "X-Token": "secret" }, body: "payload" }
      body <- text response
      statusCode response `shouldEqual` 200
      body `shouldEqual` "POST secret payload"

  it "fetches with defaults and follows redirects" do
    withServer \base -> do
      response <- fetch (URL (base <> "/old")) defaultFetchOptions
      body <- text response
      url response `shouldEqual` URL (base <> "/json")
      body `shouldEqual` "{\"name\":\"Ada\",\"age\":36}"

  it "decodes JSON" do
    withServer \base -> do
      person <- fetch (URL (base <> "/json")) {} >>= json # fromJSON
      person `shouldEqual` { name: "Ada", age: 36 }

  it "reads response headers" do
    withServer \base -> do
      response <- fetch (URL (base <> "/cookies")) {}
      Object.lookup "X-Two" (headers response) `shouldEqual` Just "a, b"
      (cookiesFromResponseHeaders (responseHeaders response) <#> _.name) `shouldEqual` [ "sid", "theme" ]

  it "fails when the server can't be reached" do
    result <- attempt $ fetch (URL "http://127.0.0.1:1/") {}
    either (const "failed") (const "reached") result `shouldEqual` "failed"

cookies :: Spec Unit
cookies = describe "cookies" do
  it "parses and renders cookie headers" do
    cookieHeader [ cookie "sid" "abc", cookie "theme" "dark" ] `shouldEqual` "sid=abc; theme=dark"
    parseCookieHeader "sid=abc; theme=dark" `shouldEqual` [ cookie "sid" "abc", cookie "theme" "dark" ]
    setCookieHeader (setCookie "sid" "abc" [ { name: "HttpOnly", value: Nothing }, { name: "Path", value: Just "/" } ]) `shouldEqual` "sid=abc; HttpOnly; Path=/"
    parseSetCookieHeader "sid=abc; HttpOnly; Path=/" `shouldEqual` setCookie "sid" "abc" [ { name: "HttpOnly", value: Nothing }, { name: "Path", value: Just "/" } ]

-- | Serves the routes the fetch specs ask for on a free port, for the length of the test.
withServer :: (String -> Aff Unit) -> Aff Unit
withServer test = bracket started HTTP.shutdown \server ->
  test ("http://" <> un Address (HTTP.serverAddress server))
  where
  started = HTTP.start (Address "127.0.0.1:0") answer # liftEffect >>= either (throwException <<< Exception.error <<< show) pure # liftEffect

  answer request = case HTTP.path request of
    Path "/echo" -> do
      body <- HTTP.body request # liftEffect
      let token = maybe "" (un HeaderValue) (HTTP.header (HeaderName "X-Token") request)
      pure $ HTTP.ok (un HTTP.Method (HTTP.method request) <> " " <> token <> " " <> either show identity body)
    Path "/old" -> pure $ HTTP.response (Status 302) "" # HTTP.withHeader (HeaderName "Location") (HeaderValue "/json")
    Path "/json" -> pure $ HTTP.ok "{\"name\":\"Ada\",\"age\":36}"
    Path "/cookies" -> pure $ HTTP.ok ""
      # HTTP.withHeader (HeaderName "X-Two") (HeaderValue "a")
      # HTTP.withHeader (HeaderName "X-Two") (HeaderValue "b")
      # HTTP.withHeader (HeaderName "Set-Cookie") (HeaderValue "sid=abc; HttpOnly")
      # HTTP.withHeader (HeaderName "Set-Cookie") (HeaderValue "theme=dark; Path=/")
    _ -> pure HTTP.notFound

testDirectory :: FilePath
testDirectory = "output/script-prelude-test"

testFile :: FilePath
testFile = testDirectory / "prelude.txt"
