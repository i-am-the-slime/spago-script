main = run do
  name <- env "USER"
  log $ fmt @"hello $name" { name }
  logShow =<< ls @"-1 $dir" { dir: "src" }
