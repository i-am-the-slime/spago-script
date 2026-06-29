module Main where

import Script.Prelude

main :: Effect Unit
main = run do
  dir <- cwd # liftEffect
  log ("script-prelude ready in " <> dir)
