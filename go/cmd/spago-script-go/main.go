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

Scripts without a module header are wrapped as a Main module importing
Script.Prelude. Statements at the top become main = run do; helpers
(definitions, signatures, data and type declarations) follow them.

Environment:
  IRIS     the iris binary (default: iris on the PATH)
  IRIS_GO  a local checkout of github.com/i-am-the-slime/iris-go to build against
`

var moduleHeader = regexp.MustCompile(`(?m)^\s*module\s+([A-Z][\w]*(?:\.[A-Z][\w]*)*)\s+where\b`)

var mainSignature = regexp.MustCompile(`(?m)^\s*main\s*::`)

// mainDefinition finds a script that defines main itself.
var mainDefinition = regexp.MustCompile(`(?m)^main\b[^=\n]*=`)

// declarationStart is a line at the left margin that begins a declaration: a keyword, a type
// signature or a definition `name arguments = …` with no `<-` before the `=`.
var declarationStart = regexp.MustCompile(
	`^(?:(?:data|type|newtype|class|instance|derive|foreign|infix|infixl|infixr)\b` +
		`|[a-z_][\w']*\s*::` +
		`|[a-z_][\w']*(?:\s[^=<\n]*)?\s=(?:\s|$))`)

// keywords begin statements even when the line has an `=`, as in `let x = 1`.
var keywords = regexp.MustCompile(`^(?:let|if|case|do|when|unless|for_|for)\b`)

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
	script, err := prepare(string(source))
	if err != nil {
		return err
	}
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

func prepare(source string) (script, error) {
	source = stripShebang(source)
	if header := moduleHeader.FindStringSubmatch(source); header != nil {
		return script{module: header[1], source: source}, nil
	}
	imports, body := splitImports(source)
	if at := bareDo(body); at >= 0 {
		body = body[:at] + "main = run " + body[at:]
	} else if !mainDefinition.MatchString(body) {
		statements, helpers, err := splitStatements(body)
		if err != nil {
			return script{}, err
		}
		if statements != "" {
			body = "main = run do\n" + indent(statements) + "\n" + helpers
		}
	}
	annotation := "main :: Effect Unit\n"
	if mainSignature.MatchString(body) {
		annotation = ""
	}
	return script{
		module: "Main",
		source: "module Main where\n\nimport Script.Prelude\n" + imports + "\n" + annotation + body,
	}, nil
}

// splitStatements separates a script's statements from the helpers after them. Each block starts
// at the left margin and takes the indented lines below it. Statements come first; from the first
// declaration on, every block must be a declaration.
func splitStatements(body string) (string, string, error) {
	var statements, helpers strings.Builder
	inHelpers := false
	declaration := false
	for _, line := range strings.SplitAfter(body, "\n") {
		trimmed := strings.TrimSpace(line)
		startsBlock := trimmed != "" && !strings.HasPrefix(trimmed, "--") &&
			line[0] != ' ' && line[0] != '\t'
		if startsBlock {
			declaration = declarationStart.MatchString(line) && !keywords.MatchString(line)
			if declaration {
				inHelpers = true
			} else if inHelpers {
				return "", "", fmt.Errorf(
					"statements come before helpers, but this one follows a helper:\n  %s", trimmed)
			}
		}
		if inHelpers {
			helpers.WriteString(line)
		} else {
			statements.WriteString(line)
		}
	}
	return strings.TrimRight(statements.String(), "\n"), helpers.String(), nil
}

// indent puts every line of a block two spaces to the right, so it becomes a do block's body.
func indent(block string) string {
	lines := strings.Split(block, "\n")
	for index, line := range lines {
		if strings.TrimSpace(line) != "" {
			lines[index] = "  " + line
		}
	}
	return strings.Join(lines, "\n")
}

// splitImports separates the script's own imports, with the comments and blank lines between
// them, from the code after them. An import continues on indented lines, as in
// `import Data.Map (Map,\n  insert)`.
func splitImports(source string) (string, string) {
	lines := strings.SplitAfter(source, "\n")
	end := 0
	for index, line := range lines {
		trimmed := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(line, "import "):
			end = index + 1
		case trimmed == "" || strings.HasPrefix(trimmed, "--"):
		case end > 0 && index == end && (line[0] == ' ' || line[0] == '\t'):
			end = index + 1
		default:
			return strings.Join(lines[:end], ""), strings.Join(lines[end:], "")
		}
	}
	return strings.Join(lines[:end], ""), strings.Join(lines[end:], "")
}

// bareDo is where the script's code starts with a bare `do` block at the left margin, which
// becomes the body of `main = run do`, or -1 when it doesn't.
func bareDo(body string) int {
	offset := 0
	for _, line := range strings.SplitAfter(body, "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "--") {
			offset += len(line)
			continue
		}
		if trimmed == "do" || strings.HasPrefix(line, "do ") || strings.HasPrefix(line, "do\t") {
			return offset
		}
		return -1
	}
	return -1
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
	command.Env = append(os.Environ(), "GOFLAGS=-mod=mod -buildvcs=false")
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
