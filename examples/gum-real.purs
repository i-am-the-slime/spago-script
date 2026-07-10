#!/usr/bin/env spago-script
main = run do
  ensureGum
  name <- gumInput "project name"
  kind <- gumChoose [ "app", "library", "script" ]
  language <- gumFilter [ "PureScript", "TypeScript", "Zig", "Go", "Rust" ]
  ok <- gumConfirm $ fmt @"Create $kind '$name' in $language?" { kind, name, language }

  if ok then do
    let dir = "tmp" / name
    mkdir @"-p $dir" { dir }
    write (dir / "README.md") $ fmt @"# $name\n\nKind: $kind\nLanguage: $language\n" { name, kind, language }
    _ <- gumSpin "Pretending to do serious work" "sleep 1"
    message <- gum [ "style", "--foreground", "212", fmt @"Gum created $dir" { dir } ]
    log message
  else do
    log "No worries."
