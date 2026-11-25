package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

const helloScript = "#!/usr/bin/env spago-script-go\nmodule Main where\n\nimport Script.Prelude\n\nmain :: Effect Unit\nmain = run do\n  log \"hello\"\n"

func initScriptFolder(t *testing.T, files map[string]string) (string, result) {
	t.Helper()
	dir := t.TempDir()
	for name, source := range files {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(source), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	command := exec.Command(binary, "init", dir)
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("init failed: %v\n%s", err, output)
	}
	return dir, result{stdout: string(output)}
}

func TestModuleNamesComeFromFileNames(t *testing.T) {
	cases := map[string]string{"hello.purs": "Hello", "list-files.purs": "ListFiles", "git_log.purs": "GitLog", "2fa.purs": "Script2fa"}
	for file, want := range cases {
		if got := moduleName(file); got != want {
			t.Errorf("moduleName(%q) = %q, want %q", file, got, want)
		}
	}
}

func TestInitNamesMainModulesAfterTheirFiles(t *testing.T) {
	dir, output := initScriptFolder(t, map[string]string{"list-files.purs": helloScript})
	if !strings.Contains(output.stdout, "list-files.purs: module Main is now module ListFiles") {
		t.Fatalf("init didn't say what it renamed: %s", output.stdout)
	}
	source, _ := os.ReadFile(filepath.Join(dir, "list-files.purs"))
	if want := strings.Replace(helloScript, "module Main", "module ListFiles", 1); string(source) != want {
		t.Fatalf("got\n%s", source)
	}
	if info, _ := os.Stat(filepath.Join(dir, "list-files.purs")); info.Mode().Perm() != 0o755 {
		t.Fatalf("the script lost its mode: %v", info.Mode())
	}
	expect(t, runFile(t, filepath.Join(dir, "list-files.purs")), result{stdout: "hello\n"})
}

func TestInitPointsTheEditorAtTheLanguageServer(t *testing.T) {
	dir, _ := initScriptFolder(t, map[string]string{})
	contents, err := os.ReadFile(filepath.Join(dir, ".vscode", "settings.json"))
	if err != nil {
		t.Fatal(err)
	}
	var settings map[string]any
	if err := json.Unmarshal(contents, &settings); err != nil {
		t.Fatal(err)
	}
	if settings["iris.client.serverPath"] != binary || settings["purescript.autoStartPscIde"] != false {
		t.Fatalf("got %s", contents)
	}
	manifest, _ := os.ReadFile(filepath.Join(dir, "spago.yaml"))
	if !strings.HasPrefix(string(manifest), manifestMarker) || !strings.Contains(string(manifest), "spago-script-go:\n      path: ") {
		t.Fatalf("got %s", manifest)
	}
}

func TestInitRunsAgainButLeavesOtherProjectsAlone(t *testing.T) {
	dir, _ := initScriptFolder(t, map[string]string{})
	if output, err := exec.Command(binary, "init", dir).CombinedOutput(); err != nil {
		t.Fatalf("init didn't run again: %s", output)
	}
	project := t.TempDir()
	os.WriteFile(filepath.Join(project, "spago.yaml"), []byte("package:\n  name: mine\n"), 0o644)
	output, err := exec.Command(binary, "init", project).CombinedOutput()
	if err == nil || !strings.Contains(string(output), "already has a spago.yaml") {
		t.Fatalf("init replaced a spago.yaml it didn't write: %s", output)
	}
}

func TestTheLanguageServerChecksScripts(t *testing.T) {
	dir, _ := initScriptFolder(t, map[string]string{
		"hello.purs":  helloScript,
		"broken.purs": strings.Replace(strings.Replace(helloScript, "module Main", "module Broken", 1), "log \"hello\"", "log 1", 1),
	})
	server := startLanguageServer(t, dir)
	if got := server.diagnostics(t, "hello.purs"); len(got) != 0 {
		t.Fatalf("a correct script with a shebang has diagnostics: %v", got)
	}
	if got := server.diagnostics(t, "broken.purs"); len(got) != 1 || !strings.Contains(got[0], "Could not match 'Int' with 'String'") {
		t.Fatalf("got %v", got)
	}
	if got := server.hover(t, "hello.purs", 7, 3); !strings.Contains(got, "log ::") {
		t.Fatalf("hover shows %q", got)
	}
}

type languageServer struct {
	dir      string
	input    io.Writer
	messages chan map[string]any
	nextID   int
}

func startLanguageServer(t *testing.T, dir string) *languageServer {
	t.Helper()
	command := exec.Command(binary, "lsp", "--stdio")
	command.Dir = dir
	input, _ := command.StdinPipe()
	output, _ := command.StdoutPipe()
	if err := command.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { input.Close(); command.Process.Kill(); command.Wait() })
	server := &languageServer{dir: dir, input: input, messages: make(chan map[string]any, 100)}
	go server.read(bufio.NewReader(output))
	root := "file://" + dir
	server.request(t, "initialize", map[string]any{"processId": os.Getpid(), "rootUri": root, "capabilities": map[string]any{}})
	server.send(map[string]any{"method": "initialized", "params": map[string]any{}})
	return server
}

func (s *languageServer) read(output *bufio.Reader) {
	relay(output, io.Discard, func(body []byte) []byte {
		var message map[string]any
		json.Unmarshal(body, &message)
		s.messages <- message
		return body
	})
	close(s.messages)
}

func (s *languageServer) send(message map[string]any) {
	message["jsonrpc"] = "2.0"
	body, _ := json.Marshal(message)
	fmt.Fprintf(s.input, "Content-Length: %d\r\n\r\n%s", len(body), body)
}

func (s *languageServer) request(t *testing.T, method string, params map[string]any) any {
	t.Helper()
	s.nextID++
	id := float64(s.nextID)
	s.send(map[string]any{"id": id, "method": method, "params": params})
	message := s.await(t, func(message map[string]any) bool { return message["id"] == id && message["method"] == nil })
	return message["result"]
}

func (s *languageServer) await(t *testing.T, wanted func(map[string]any) bool) map[string]any {
	t.Helper()
	timeout := time.After(2 * time.Minute)
	for {
		select {
		case message, open := <-s.messages:
			if !open {
				t.Fatal("the language server stopped")
			}
			if wanted(message) {
				return message
			}
		case <-timeout:
			t.Fatal("the language server didn't answer")
		}
	}
}

func (s *languageServer) uri(file string) string { return "file://" + filepath.Join(s.dir, file) }

func (s *languageServer) diagnostics(t *testing.T, file string) []string {
	t.Helper()
	text, _ := os.ReadFile(filepath.Join(s.dir, file))
	uri := s.uri(file)
	s.send(map[string]any{"method": "textDocument/didOpen", "params": map[string]any{
		"textDocument": map[string]any{"uri": uri, "languageId": "purescript", "version": 1, "text": string(text)},
	}})
	message := s.await(t, func(message map[string]any) bool {
		params, _ := message["params"].(map[string]any)
		return message["method"] == "textDocument/publishDiagnostics" && params["uri"] == uri
	})
	var messages []string
	for _, diagnostic := range message["params"].(map[string]any)["diagnostics"].([]any) {
		messages = append(messages, diagnostic.(map[string]any)["message"].(string))
	}
	return messages
}

func (s *languageServer) hover(t *testing.T, file string, line int, character int) string {
	t.Helper()
	result := s.request(t, "textDocument/hover", map[string]any{
		"textDocument": map[string]any{"uri": s.uri(file)},
		"position":     map[string]any{"line": line, "character": character},
	})
	contents, _ := json.Marshal(result)
	return string(contents)
}

func TestTheShebangReachesIrisAsAComment(t *testing.T) {
	proxy := newShebangProxy()
	open := `{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///s/hello.purs","version":1,"text":"#!/usr/bin/env gogogo\nmodule Hello where\n"}}}`
	if got := string(proxy.fromEditor([]byte(open))); !strings.Contains(got, `"text":"--/usr/bin/env gogogo\nmodule Hello where\n"`) {
		t.Fatalf("got %s", got)
	}
	edit := `{"jsonrpc":"2.0","method":"textDocument/didChange","params":{"textDocument":{"uri":"file:///s/hello.purs","version":2},"contentChanges":[{"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":0}},"text":"#!"}]}}`
	if got := string(proxy.fromEditor([]byte(edit))); got != edit {
		t.Fatalf("an edit of a range changed: %s", got)
	}
	format := `{"jsonrpc":"2.0","id":7,"method":"textDocument/formatting","params":{"textDocument":{"uri":"file:///s/hello.purs"},"options":{}}}`
	proxy.fromEditor([]byte(format))
	formatted := `{"jsonrpc":"2.0","id":7,"result":[{"range":{"start":{"line":0,"character":0},"end":{"line":9,"character":0}},"newText":"--/usr/bin/env gogogo\nmodule Hello where\n"}]}`
	if got := string(proxy.fromServer([]byte(formatted))); !strings.Contains(got, `"newText":"#!/usr/bin/env gogogo\nmodule Hello where\n"`) {
		t.Fatalf("formatting lost the shebang: %s", got)
	}
	other := `{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///s/Other.purs","version":1,"text":"module Other where\n"}}}`
	if got := string(proxy.fromEditor([]byte(other))); got != other {
		t.Fatalf("a document without a shebang changed: %s", got)
	}
}
