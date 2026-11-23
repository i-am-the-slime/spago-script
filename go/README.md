# spago-script-go

PureScript scripts that run as native programs. Same `Script.Prelude` as
[spago-script](../README.md), compiled to Go with [Iris](https://github.com/i-am-the-slime/purescript-analyzer/tree/iris-go).

```purescript
name <- input "project name"
log (greet name)

greet :: String -> String
greet name = "Hello " <> name
```

Write your statements at the top and your helpers below them. The statements become
`main = run do`, so they run in order; helpers can be used anywhere. Put imports above
everything:

```purescript
import Data.Array (length)

files <- listDir "."
log (show (length files) <> " files")
```

You can also start the script with a bare `do`, or write `main = run do` yourself.

```sh
spago-script-go ./hello.purs
```

The first run of a script compiles it, which takes a second or two. After that it starts in about
10 ms. Change the script and it compiles again.

## Requirements

- Iris with the Go backend, on your `PATH` or in `IRIS`.
- Go. It downloads the toolchain it needs by itself.
- Network access on the first run, to download PureScript and Go packages.
- Whatever programs your script calls, such as `git`, `rg` or `gum`.

## Install

```sh
git clone https://github.com/i-am-the-slime/spago-script
cd spago-script/go
iris run --go -p spago-script-go-tasks --entry Tasks.Build.main -- ~/.local/bin/spago-script-go
```

That's one binary with the prelude inside. The build itself is a PureScript program, in `tasks`.
Set `PURESCRIPT_GO` to a [purescript-go](https://github.com/i-am-the-slime/purescript-go) checkout
to bundle its packages from there instead of the commit `spago.yaml` pins. Compiled scripts live in
`~/.cache/spago-script-go` (or `$XDG_CACHE_HOME/spago-script-go`). Delete its `bin` folder
whenever you like, scripts just compile again.

## Shebang scripts

```purescript
#!/usr/bin/env spago-script-go
main = run do
  log "Hello from a native PureScript script"
```

```sh
chmod +x ./script.purs
./script.purs
```

## Script arguments

```sh
spago-script-go ./script.purs one "two words"
```

```purescript
main = run do
  values <- args # liftEffect
  logShow values
```

```
["one","two words"]
```

## Editor support

Keep your scripts in a folder and turn it into a script folder:

```sh
cd ~/scripts
spago-script-go init
```

Then open the folder in VS Code with the
[purescript-iris](https://marketplace.visualstudio.com/items?itemName=purefunctor.purescript-analyzer)
extension enabled. You get types on hover and errors for `Script.Prelude`, the Go bindings and
everything else a script can import.

For that, a script is a regular module named after its file, so the scripts in one folder
don't get in each other's way:

```purescript
#!/usr/bin/env spago-script-go
module Hello where

import Script.Prelude

main :: Effect Unit
main = run do
  log "Hello"
```

That's `hello.purs`. `init` renames any `module Main` it finds that way and tells you. The
shebang line is fine, the editor sees it as a comment. The short scripts without a `main` still
run, the editor just doesn't understand them.

`init` writes a `spago.yaml` and `.vscode/settings.json` into the folder. Run it again after
updating spago-script-go.

## The prelude

Everything in the [spago-script prelude](../README.md#prelude-api) works the same: files,
`x` and `cmd`, typed commands, pipes, prompts, spinners, `gum`, JSON, `fmt`, `Yoga.Om`.

```purescript
main = run do
  write "hello.txt" "hello"
  branch <- x "git" [ "branch", "--show-current" ]
  firstTwo <- head @"-n $count $file" { count: 2, file: "hello.txt" }
  matches <- cat @"$file" { file: "hello.txt" } |> "grep hello"
  log $ fmt @"$branch / $firstTwo / $matches" { branch, firstTwo, matches }
```

```
main / hello / hello
```

The examples in [examples](examples) run as they are.

## HTTP

`fetch` takes the URL and the options you want to change: `method`, `headers` and `body`.

```purescript
main = run do
  response <- fetch (URL "https://api.github.com/repos/purescript/purescript") defaultFetchOptions # liftAff
  repo :: { stargazers_count :: Int } <- json response # fromJSON # liftAff
  log $ "PureScript has " <> show repo.stargazers_count <> " stars"
```

```purescript
fetch (URL "https://example.com/api") { method: postMethod, headers: makeHeaders { "Content-Type": "application/json" }, body: writeJSON { name: "Ada" } }
```

Read the response with `text`, `json`, `bytes`, `statusCode`, `headers` and `url`. Redirects are
followed. `responseHeaders` keeps every `Set-Cookie` apart, for `cookiesFromResponseHeaders`.

## SQLite

Built in, no `sqlite3` needed:

```purescript
main = run do
  version <- querySQLiteText (SQLitePath ":memory:") (SQLiteQuery "select sqlite_version()") # liftAff
  log $ "SQLite " <> version
```

Files open read-only.

## Helpers

A few more modules for the things scripts keep doing. Import what you need:

| Module | |
| --- | --- |
| `Script.Files` | `filesUnder` and `filesEndingWith` walk a directory, `copyTree` copies one, `readJSONFile` and `writeJSONFile`, `scriptDirectory` (that's `$(dirname "$0")`), `changeDirectory` |
| `Script.Environment` | `setEnv`, `unsetEnv`, `setEnvUnlessSet` (that's `export X=${X:-value}`), `envOr` |
| `Script.Text` | `substitute` (a `sed s|…|…|g` without regular expressions), `linesOf`, `trimEnd`, `padLeft`, `padRight`, `decimals` (that's `toFixed`) |
| `Script.Baseline` | keep scores in a JSON file and `judge` new ones against them: `Regressed`, `Improved`, `Steady` or `New` |
| `Script.Table` | `markdownTable` and `alignedTable` |
| `Script.Statistics` | `median` and `percentOf` |
| `Script.Timing` | `timed` an action, or `timedRuns` with warmups |
| `Script.Hyperfine` | runs commands with [hyperfine](https://github.com/sharkdp/hyperfine) and hands back every run, with medians |

```purescript
import Script.Hyperfine (defaultBenchmark, hyperfine)
import Script.Table (alignedTable)

results <- hyperfine defaultBenchmark { commands = [ "sleep 0.1", "sleep 0.2" ] }
log (alignedTable [ "command", "median" ] (results <#> \r -> [ r.command, show r.medianWallSeconds ]))
```

```
command    median
sleep 0.1  0.104…
sleep 0.2  0.205…
```

## Go's standard library

Write a module header and import the Go bindings from
[purescript-go](https://github.com/i-am-the-slime/purescript-go) (`Go.OS`, `Go.OS.Exec`,
`Go.Net.HTTP`, `Go.Path.Filepath`, `Go.Time`, `Go.IO`, …) for anything the prelude doesn't have:

```purescript
module Main where

import Script.Prelude

import Go.FilePath (FilePath(..))
import Go.OS (FileMode(..))
import Go.OS as OS

main :: Effect Unit
main = run do
  _ <- OS.chmod (FilePath "hello.txt") (FileMode 384) # liftEffect
  log "hello.txt is yours alone now"
```

## Different from the Bun version

- **No JavaScript.** Packages with JavaScript foreign code don't compile, so no `node-*` or `js-*`.
  Pure PureScript packages and Go-backed ones work.
- **`fetch`** needs no `FetchImpl`, and takes only `method`, `headers` and `body`.
  `Yoga.Fetch.Om`'s `deriveClient` isn't there.
- **Text files are UTF-8.** `Encoding` has only `UTF8`, and `Buffer` is Go's bytes.
- **Processes.** `ExecaOptions` has `cwd`, `env`, `extendEnv`, `input`, `stdin`, `stdout`,
  `stderr` and `stripFinalNewline`. Feed a program text with `input`. A spawned process has
  `getResult` and `kill`.
- **File errors** read like `no such file or directory: notes.txt`.

## Testing

```sh
iris run --go -p spago-script-go-tasks --entry Tasks.Test.main
```

runs the prelude's specs, the CLI tests and the prompt tests.
