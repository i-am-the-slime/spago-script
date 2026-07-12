# spago-script

Run small PureScript scripts with `Script.Prelude` preloaded.

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
