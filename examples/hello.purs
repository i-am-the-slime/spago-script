main = run do
  name <- env "USER"
  logFmt @"Hello $name" { name }
  log =<< ls @"-1 $dir" { dir: "src" }
