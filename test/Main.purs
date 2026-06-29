module Test.Main where

import Script.Prelude

import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  describe "script prelude" do
    it "reads, writes, appends, and checks files" do
      mkdirp testDirectory
      writeTextFile testFile "hello"
      appendTextFile testFile " script"
      contents <- readTextFile testFile
      exists <- fileExists testFile
      dirExists <- directoryExists testDirectory
      contents `shouldEqual` "hello script"
      exists `shouldEqual` true
      dirExists `shouldEqual` true
      removeFile testFile
      gone <- fileExists testFile
      gone `shouldEqual` false
    it "lists directories" do
      removeDir testDirectory
      mkdirp testDirectory
      writeTextFile testFile "listed"
      entries <- listDir testDirectory
      entries `shouldEqual` [ "prelude.txt" ]
      removeDir testDirectory
    it "reads process information" do
      workingDirectory <- cwd # liftEffect
      scriptArgs <- args # liftEffect
      missing <- lookupEnv "SPAGO_SCRIPT_PRELUDE_MISSING_FOR_TEST" # liftEffect
      (workingDirectory == "") `shouldEqual` false
      scriptArgs `shouldEqual` []
      missing `shouldEqual` Nothing
    it "runs commands and shell snippets" do
      result <- exec "bun" [ "--eval", "console.log('ok')" ]
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
    it "runs execa helpers" do
      output <- x "bun" [ "--eval", "console.log('execa')" ]
      commandOutput <- cmd "printf command"
      output `shouldEqual` "execa"
      commandOutput `shouldEqual` "command"
    it "uses reader cwd for execa helpers" do
      output <- runAffWith { cwd: testDirectory } do
        mkdirp testDirectory
        write (testDirectory / "cwd.txt") "from reader"
        cmdHere "cat cwd.txt"
      output `shouldEqual` "from reader"
    it "formats strings" do
      fmt @"hello $name" { name: "scripts" } `shouldEqual` "hello scripts"
      logFmt @"hello $name" { name: "scripts" }
    it "runs command aliases and pipes output" do
      write (testDirectory / "pipe.txt") "pipe"
      listed <- ls_ @"output/script-prelude-test"
      listedWithArgs <- lsArgs [ testDirectory ]
      listedWithFlatArgs <- lsArgs ("-1 " <> testDirectory)
      listedWithTemplate <- ls @"-1 $dir" { dir: testDirectory }
      piped <- x "printf" [ "one\ntwo\n" ] |> "grep two"
      pipedBackwards <- "grep one" <| x "printf" [ "one\ntwo\n" ]
      listed `shouldEqual` "cwd.txt\npipe.txt\nprelude.txt"
      listedWithArgs `shouldEqual` "cwd.txt\npipe.txt\nprelude.txt"
      listedWithFlatArgs `shouldEqual` "cwd.txt\npipe.txt\nprelude.txt"
      listedWithTemplate `shouldEqual` "cwd.txt\npipe.txt\nprelude.txt"
      piped `shouldEqual` "two"
      pipedBackwards `shouldEqual` "one"
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


testDirectory :: FilePath
testDirectory = "output/script-prelude-test"

testFile :: FilePath
testFile = testDirectory / "prelude.txt"
