# spago-script

Run small PureScript scripts with `Script.Prelude` preloaded.

## Requirements

- [Bun](https://bun.sh/) 1.2 or newer.
- Network access on the first run so Spago can download PureScript packages.
- Any external programs used by the script, such as `git`, `rg`, or `gum`.

The CLI package supplies compatible `purescript` and `spago` executables. Compiled
dependencies are cached under `$XDG_CACHE_HOME/spago-script-prelude`, or
`~/.cache/spago-script-prelude` when `XDG_CACHE_HOME` is unset. Each invocation
uses isolated compiler output and removes its temporary project on exit.

## Quickstart

Create a script:

```purescript
main = run do
  name <- input "project name"
  log $ "Hello " <> name
```

Run it directly from GitHub with Bun:

```sh
bunx --package github:i-am-the-slime/spago-script spago-script ./script.purs
```

Or install the command globally:

```sh
bun add -g github:i-am-the-slime/spago-script
spago-script ./script.purs
```

Want a native binary instead of Bun? [spago-script-go](go/README.md) runs the same scripts
compiled to Go.

## Shebang scripts

Make a file executable:

```purescript
#!/usr/bin/env spago-script
main = run do
  log "Hello from a PureScript script"
```

Then run:

```sh
chmod +x ./script.purs
./script.purs
```

## Script arguments

Arguments after the script path are passed through:

```sh
spago-script ./script.purs one two three
```

Read them with:

```purescript
main = run do
  values <- args # liftEffect
  logShow values
```

## Prelude

Scripts without a module header are wrapped as:

```purescript
module Main where

import Script.Prelude

main :: Effect Unit
```

So this is enough:

```purescript
main = run do
  write "hello.txt" "hello"
  text <- read "hello.txt"
  log text
```

## PureScript package

`spago-script` is also published on the PureScript registry:

```sh
spago install spago-script
```

Then import the prelude in a normal PureScript project:

```purescript
import Script.Prelude
```

## Prelude API

`Script.Prelude` re-exports the standard PureScript prelude plus the modules
needed for effects, `Aff`, JSON, HTTP requests, formatting, and `Yoga.Om`.
Frequently used scripting helpers are grouped below.

| Area | Helpers |
| --- | --- |
| Script runtime | `run`, `runWith`, `runAff`, `args`, `cwd`, `env`, `lookupEnv` |
| Filesystem | `read`, `write`, `append`, `copy`, `mkdirp`, `listDir`, `exists`, `rm` |
| Processes | `x`, `x_`, `cmd`, `cmd_`, `exec`, `spawn`, `pipeInto`, `pipeFrom` |
| Typed commands | `ls`, `cp`, `mv`, `grep`, `find`, `rg`, `git`, `spago`, and their `_`/`Args` variants |
| Prompts | `input`, `choose`, `confirm`, `select`, `file`, `writeNative`, `spin` |
| Data and HTTP | Yoga JSON/fetch exports plus cookie header helpers |
| Output | `log`, `logShow`, `logFmt`, `style`, `markdown`, `table` |

`x` executes a program with an argument array and returns trimmed stdout:

```purescript
main = run do
  branch <- x "git" [ "branch", "--show-current" ]
  log branch
```

`cmd` executes a shell command. Prefer `x` when arguments contain user input;
it avoids shell interpolation.

```purescript
main = run do
  count <- cmd "find src -name '*.purs' | wc -l"
  log count
```

## Typed command grammars

Typed wrappers parse the type-level argument template into real argv tokens.
Their command grammar checks exact options, required option operands, semantic
operand types, positional order and cardinality, and supported subcommands.
Record fields provide values for `$placeholders`:

```purescript
main = run do
  firstTwo <- head @"-n $count $file"
    { count: 2
    , file: "names.txt"
    }
  log firstTwo
```

Here `count` must be an `Int`, `file` must be a `String`, and `head` must accept
the complete argv shape. A `Boolean` count or unknown option fails compilation;
fixed-arity tools such as `cp` also reject missing or excess positionals.

Quoting and interpolation preserve argv boundaries without invoking a shell:

```purescript
contents <- cat @"$file" { file: "names with spaces.txt" }
same <- cat_ @"'names with spaces.txt'"
```

Each command family has three variants:

- `head @"..." { ... }` — checked template with record interpolation.
- `head_ @"..."` — fully static checked template.
- `headArgs [ ... ]` — unchecked runtime argv escape hatch.

Typed commands can also be downstream pipeline stages:

```purescript
matched <-
  cat @"$file" { file: "names.txt" }
    |> typedCommand @GrepGrammarDefinition @"$pattern" { pattern: "Grace" }
```

The existing string form remains available when a shell pipeline is intended:

```purescript
matched <- cat @"$file" { file: "names.txt" } |> "grep Grace"
```

### Adding a tool

Grammars are declarations assembled from reusable option and positional
constructors. A new wrapper needs one grammar alias and one executor:

```purescript
type EchoGrammar =
  Command "echo"
    NoOptions
    (AddPositional "TEXT" TextValue Some NoPositionals)
    NoSubcommands

echo
  :: forall @args input m
   . TypedArgs EchoGrammar args input
  => MonadAff m
  => input
  -> m String
echo input = x "echo" (typedArgs @EchoGrammar @args input)
```

Use `read` for direct filesystem reads; `cat` is the checked external command.
Compile errors and script exit statuses are passed through to the caller.
