#!/usr/bin/env spago-script
main = run do
  name <- inputNative "project name"
  kind <- chooseNative [ "app", "library", "script" ]
  language <- select [ "PureScript", "TypeScript", "Zig", "Go", "Rust" ]
  ok <- confirmNative $ fmt @"Create $kind '$name' in $language?" { kind, name, language }

  if ok then do
    let dir = "tmp" / name
    mkdir @"-p $dir" { dir }
    write (dir / "README.md") $ fmt @"# $name\n\nKind: $kind\nLanguage: $language\n" { name, kind, language }
    spinNative "Pretending to do serious work" "sleep 1"
    message <- styleNative "212" $ fmt @"Native created $dir" { dir }
    log message
  else do
    log "No worries."
