#!/usr/bin/env spago-script
main = run do
  name <- input "project name"
  kind <- choose [ "app", "library", "script" ]
  language <- select [ "PureScript", "TypeScript", "Zig", "Go", "Rust" ]
  ok <- confirm $ fmt @"Create $kind '$name' in $language?" { kind, name, language }

  if ok then do
    let dir = "tmp" / name
    mkdir @"-p $dir" { dir }
    write (dir / "README.md") $ fmt @"# $name\n\nKind: $kind\nLanguage: $language\n" { name, kind, language }
    spin "Pretending to do serious work" "sleep 1"
    message <- style "212" $ fmt @"Created $dir" { dir }
    log message
  else do
    log "No worries."
