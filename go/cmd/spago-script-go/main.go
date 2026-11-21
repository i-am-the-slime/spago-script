// spago-script-go runs a PureScript script as a native program: it compiles the script with Iris's
// Go backend and `go build`, caches the binary by the script's content, and runs it.
package main

import (
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
)

// bundle holds Script.Prelude for Go and the packages it needs that aren't on the registry, as
// build.sh copies them, plus the Go module the script compiles into. That one is go.mod.template,
// because embed leaves out directories with a go.mod.
//
//go:embed all:bundle
var bundle embed.FS

const usage = `Usage: spago-script-go <script.purs> [args...]

Compiles the script to a native binary with Iris and Go, caches it by the
script's content, and runs it with the arguments.

Scripts without a module header are wrapped as:

  module Main where
  import Script.Prelude

  main :: Effect Unit
  <script contents>

Environment:
  IRIS     the iris binary (default: iris on the PATH)
  IRIS_GO  a local checkout of github.com/i-am-the-slime/iris-go to build against
`

var moduleHeader = regexp.MustCompile(`(?m)^\s*module\s+([A-Z][\w]*(?:\.[A-Z][\w]*)*)\s+where\b`)

var mainSignature = regexp.MustCompile(`(?m)^\s*main\s*::`)

func main() {
	if len(os.Args) < 2 || os.Args[1] == "--help" || os.Args[1] == "-h" {
		fmt.Print(usage)
		if len(os.Args) < 2 {
			os.Exit(1)
		}
		return
	}
	scriptPath, scriptArgs := os.Args[1], os.Args[2:]
	if err := run(scriptPath, scriptArgs); err != nil {
		var exit exitError
		if errors.As(err, &exit) {
			os.Exit(exit.code)
		}
		fmt.Fprintln(os.Stderr, "spago-script-go:", err)
		os.Exit(1)
	}
}

// run finds the script's binary in the cache, builds it if it isn't there, and replaces this
// process with it.
func run(scriptPath string, scriptArgs []string) error {
	source, err := os.ReadFile(scriptPath)
	if err != nil {
		return err
	}
	script := prepare(string(source))
	iris, err := irisBinary()
	if err != nil {
		return err
	}
	cache, err := cacheDir()
	if err != nil {
		return err
	}
	binary := filepath.Join(cache, "bin", script.hash(iris))
	if _, err := os.Stat(binary); err != nil {
		if err := build(cache, iris.path, script, binary); err != nil {
			return err
		}
	}
	return syscall.Exec(binary, append([]string{scriptPath}, scriptArgs...), os.Environ())
}

// script is a script as Iris compiles it: a module, and the name it goes by.
type script struct {
	module string
	source string
}

func prepare(source string) script {
	source = stripShebang(source)
	if header := moduleHeader.FindStringSubmatch(source); header != nil {
		return script{module: header[1], source: source}
	}
	annotation := "main :: Effect Unit\n"
	if mainSignature.MatchString(source) {
		annotation = ""
	}
	return script{module: "Main", source: "module Main where\n\nimport Script.Prelude\n\n" + annotation + source}
}

func stripShebang(source string) string {
	if !strings.HasPrefix(source, "#!") {
		return source
	}
	if end := strings.IndexByte(source, '\n'); end >= 0 {
		return source[end+1:]
	}
	return ""
}

// hash names the binary: the same script, prelude, Iris and runtime give the same binary.
func (s script) hash(iris irisInfo) string {
	digest := sha256.New()
	for _, part := range []string{bundleHash(), iris.stamp, os.Getenv("IRIS_GO"), s.module, s.source} {
		io.WriteString(digest, part)
		digest.Write([]byte{0})
	}
	return hex.EncodeToString(digest.Sum(nil))[:32]
}

// build compiles the script in the shared project, one build at a time, and moves the binary to
// where run looks for it.
func build(cache string, iris string, s script, binary string) error {
	project := filepath.Join(cache, "project", projectKey())
	if err := os.MkdirAll(project, 0o755); err != nil {
		return err
	}
	unlock, err := lock(filepath.Join(project, ".lock"))
	if err != nil {
		return err
	}
	defer unlock()
	if _, err := os.Stat(binary); err == nil {
		return nil
	}
	if err := materialize(project); err != nil {
		return err
	}
	if err := writeScript(project, s); err != nil {
		return err
	}
	out := filepath.Join(project, "out")
	if err := quietly(project, iris, "go", "--entry", s.module+".main", out); err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(binary), 0o755); err != nil {
		return err
	}
	partial := binary + ".partial"
	if err := quietly(out, "go", "build", "-o", partial, "."); err != nil {
		return err
	}
	return os.Rename(partial, binary)
}

// materialize writes the embedded prelude, packages and Go module into the project, once.
func materialize(project string) error {
	marker := filepath.Join(project, ".materialized")
	if _, err := os.Stat(marker); err == nil {
		return nil
	}
	err := fs.WalkDir(bundle, "bundle", func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		target := filepath.Join(project, strings.TrimSuffix(strings.TrimPrefix(path, "bundle"), ".template"))
		if entry.IsDir() {
			return os.MkdirAll(target, 0o755)
		}
		contents, err := bundle.ReadFile(path)
		if err != nil {
			return err
		}
		return os.WriteFile(target, contents, 0o644)
	})
	if err != nil {
		return err
	}
	if err := pointAtLocalRuntime(filepath.Join(project, "out", "go.mod")); err != nil {
		return err
	}
	return os.WriteFile(marker, nil, 0o644)
}

// pointAtLocalRuntime builds against a local iris-go checkout when IRIS_GO names one.
func pointAtLocalRuntime(goMod string) error {
	local := os.Getenv("IRIS_GO")
	if local == "" {
		return nil
	}
	file, err := os.OpenFile(goMod, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintf(file, "\nreplace github.com/i-am-the-slime/iris-go => %s\n", local)
	return errors.Join(err, file.Close())
}

// writeScript makes the script the only module of the project's own package.
func writeScript(project string, s script) error {
	sources := filepath.Join(project, "src")
	if err := os.RemoveAll(sources); err != nil {
		return err
	}
	path := filepath.Join(sources, filepath.FromSlash(strings.ReplaceAll(s.module, ".", "/"))+".purs")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(s.source), 0o644)
}

// quietly runs a build step and shows its output only if it fails.
func quietly(dir string, program string, args ...string) error {
	command := exec.Command(program, args...)
	command.Dir = dir
	command.Env = append(os.Environ(), "GOFLAGS=-mod=mod")
	output, err := command.CombinedOutput()
	if err == nil {
		return nil
	}
	os.Stderr.Write(output)
	var exit *exec.ExitError
	if errors.As(err, &exit) {
		return exitError{code: exit.ExitCode()}
	}
	return fmt.Errorf("%s: %w", program, err)
}

type exitError struct{ code int }

func (e exitError) Error() string { return fmt.Sprintf("exit status %d", e.code) }

// irisInfo is the iris binary and a stamp that changes when it is replaced.
type irisInfo struct {
	path  string
	stamp string
}

func irisBinary() (irisInfo, error) {
	name := os.Getenv("IRIS")
	if name == "" {
		name = "iris"
	}
	path, err := exec.LookPath(name)
	if err != nil {
		return irisInfo{}, fmt.Errorf("can't find Iris (%s); install it or point IRIS at it", name)
	}
	info, err := os.Stat(path)
	if err != nil {
		return irisInfo{}, err
	}
	return irisInfo{path: path, stamp: fmt.Sprintf("%s %d %d", path, info.Size(), info.ModTime().UnixNano())}, nil
}

func cacheDir() (string, error) {
	root := os.Getenv("XDG_CACHE_HOME")
	if root == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		root = filepath.Join(home, ".cache")
	}
	return filepath.Join(root, "spago-script-go"), nil
}

// projectKey names the project a script compiles in: one per prelude and runtime.
func projectKey() string {
	digest := sha256.Sum256([]byte(bundleHash() + "\x00" + os.Getenv("IRIS_GO")))
	return hex.EncodeToString(digest[:])[:16]
}

var bundleDigest string

// bundleHash identifies the embedded prelude, so that a new version gets a fresh project.
func bundleHash() string {
	if bundleDigest != "" {
		return bundleDigest
	}
	digest := sha256.New()
	fs.WalkDir(bundle, "bundle", func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return err
		}
		contents, err := bundle.ReadFile(path)
		io.WriteString(digest, path)
		digest.Write(contents)
		return err
	})
	bundleDigest = hex.EncodeToString(digest.Sum(nil))[:16]
	return bundleDigest
}

func lock(path string) (func(), error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(file.Fd()), syscall.LOCK_EX); err != nil {
		file.Close()
		return nil, err
	}
	return func() {
		syscall.Flock(int(file.Fd()), syscall.LOCK_UN)
		file.Close()
	}, nil
}
