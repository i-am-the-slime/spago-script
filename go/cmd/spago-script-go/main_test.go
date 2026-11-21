package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

// These tests run the real binary, Iris and Go. Run ../../build.sh first, so the bundle exists.

var binary string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "spago-script-go-test-")
	if err != nil {
		panic(err)
	}
	binary = filepath.Join(dir, "spago-script-go")
	if output, err := exec.Command("go", "build", "-o", binary, ".").CombinedOutput(); err != nil {
		panic(string(output))
	}
	if os.Getenv("XDG_CACHE_HOME") == "" {
		os.Setenv("XDG_CACHE_HOME", filepath.Join(dir, "cache"))
	}
	code := m.Run()
	os.RemoveAll(dir)
	os.Exit(code)
}

type result struct {
	code   int
	stdout string
	stderr string
}

func runScript(t *testing.T, name string, source string, args ...string) result {
	t.Helper()
	script := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(script, []byte(source), 0o755); err != nil {
		t.Fatal(err)
	}
	return runFile(t, script, args...)
}

func runFile(t *testing.T, script string, args ...string) result {
	t.Helper()
	command := exec.Command(binary, append([]string{script}, args...)...)
	var stdout, stderr bytes.Buffer
	command.Stdout, command.Stderr = &stdout, &stderr
	err := command.Run()
	code := 0
	if exit, ok := err.(*exec.ExitError); ok {
		code = exit.ExitCode()
	} else if err != nil {
		t.Fatal(err)
	}
	return result{code: code, stdout: stdout.String(), stderr: stderr.String()}
}

func expect(t *testing.T, got result, want result) {
	t.Helper()
	if got != want {
		t.Fatalf("got %+v\nwant %+v", got, want)
	}
}

func TestRunsAScriptWithItsArguments(t *testing.T) {
	got := runScript(t, "args.purs", "main = run do\n  values <- args # liftEffect\n  logShow values\n", "one", "two words")
	expect(t, got, result{stdout: "[\"one\",\"two words\"]\n"})
}

func TestPassesTheExitCodeThrough(t *testing.T) {
	got := runScript(t, "exit.purs", "main = run do\n  log \"leaving\"\n  exit 3 # liftEffect\n")
	expect(t, got, result{code: 3, stdout: "leaving\n"})
}

func TestReportsAnUncaughtErrorAndExitsWithOne(t *testing.T) {
	got := runScript(t, "fail.purs", "main = run do\n  _ <- x \"sh\" [ \"-c\", \"exit 2\" ]\n  log \"unreachable\"\n")
	expect(t, got, result{code: 1, stderr: "Command failed with exit code 2: sh -c \"exit 2\"\n"})
}

func TestStopsWithTheCompilerErrorWhenAScriptDoesNotCompile(t *testing.T) {
	got := runScript(t, "invalid.purs", "main = this does not compile\n")
	if got.code == 0 || !strings.Contains(got.stderr, "NotInScope") {
		t.Fatalf("expected a compile error, got %+v", got)
	}
}

func TestRunsAScriptWithItsOwnModuleHeader(t *testing.T) {
	source := "module Tools.Greet where\n\nimport Script.Prelude\n\nmain :: Effect Unit\nmain = run do\n  log \"own module\"\n"
	expect(t, runScript(t, "greet.purs", source), result{stdout: "own module\n"})
}

func TestStripsTheShebang(t *testing.T) {
	expect(t, runScript(t, "shebang.purs", "#!/usr/bin/env spago-script-go\nmain = run do\n  log \"shebang\"\n"), result{stdout: "shebang\n"})
}

func TestQueriesSQLite(t *testing.T) {
	got := runScript(t, "sqlite.purs", "main = run do\n  value <- querySQLiteText (SQLitePath \":memory:\") (SQLiteQuery \"select 'sqlite-ok'\") # liftAff\n  log value\n")
	expect(t, got, result{stdout: "sqlite-ok\n"})
}

func TestReusesTheBinaryUntilTheScriptChanges(t *testing.T) {
	script := filepath.Join(t.TempDir(), "cached.purs")
	os.WriteFile(script, []byte("main = run do\n  log \"first\"\n"), 0o644)
	expect(t, runFile(t, script), result{stdout: "first\n"})
	before := binaries(t)
	expect(t, runFile(t, script), result{stdout: "first\n"})
	if after := binaries(t); after != before {
		t.Fatalf("the second run built again: %d binaries, then %d", before, after)
	}
	os.WriteFile(script, []byte("main = run do\n  log \"second\"\n"), 0o644)
	expect(t, runFile(t, script), result{stdout: "second\n"})
}

func TestBuildsScriptsThatRunAtTheSameTime(t *testing.T) {
	var wait sync.WaitGroup
	results := make([]result, 6)
	for index := range results {
		wait.Add(1)
		go func() {
			defer wait.Done()
			results[index] = runScript(t, fmt.Sprintf("parallel-%d.purs", index), fmt.Sprintf("main = run do\n  log \"script %d\"\n", index))
		}()
	}
	wait.Wait()
	for index, got := range results {
		expect(t, got, result{stdout: fmt.Sprintf("script %d\n", index)})
	}
}

func binaries(t *testing.T) int {
	t.Helper()
	entries, err := os.ReadDir(filepath.Join(os.Getenv("XDG_CACHE_HOME"), "spago-script-go", "bin"))
	if err != nil {
		t.Fatal(err)
	}
	return len(entries)
}
