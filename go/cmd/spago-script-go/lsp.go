package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/textproto"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
)

// serveLanguage runs Iris's language server between the editor and Iris. Iris can't parse a
// shebang line, so the server sees it as a comment of the same length: `#!/usr/bin/env gogogo`
// becomes `--/usr/bin/env gogogo`, and every position stays where it is. Formatting edits get
// their shebang back.
func serveLanguage(args []string) error {
	iris, err := irisBinary()
	if err != nil {
		return err
	}
	server := exec.Command(iris.path, append([]string{"lsp"}, args...)...)
	server.Stderr = os.Stderr
	toServer, err := server.StdinPipe()
	if err != nil {
		return err
	}
	fromServer, err := server.StdoutPipe()
	if err != nil {
		return err
	}
	if err := server.Start(); err != nil {
		return err
	}
	proxy := newShebangProxy()
	go func() {
		relay(bufio.NewReader(os.Stdin), toServer, proxy.fromEditor)
		toServer.Close()
	}()
	relay(bufio.NewReader(fromServer), os.Stdout, proxy.fromServer)
	if err := server.Wait(); err != nil {
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			return exitError{code: exit.ExitCode()}
		}
		return err
	}
	return nil
}

// relay copies LSP messages from in to out, passing each through rewrite.
func relay(in *bufio.Reader, out io.Writer, rewrite func([]byte) []byte) {
	headers := textproto.NewReader(in)
	for {
		header, err := headers.ReadMIMEHeader()
		if err != nil {
			return
		}
		length, err := strconv.Atoi(header.Get("Content-Length"))
		if err != nil {
			return
		}
		body := make([]byte, length)
		if _, err := io.ReadFull(in, body); err != nil {
			return
		}
		body = rewrite(body)
		if _, err := fmt.Fprintf(out, "Content-Length: %d\r\n\r\n%s", len(body), body); err != nil {
			return
		}
	}
}

// shebangProxy remembers which documents start with a shebang, and which formatting requests
// are for them.
type shebangProxy struct {
	mutex      sync.Mutex
	documents  map[string]bool
	formatting map[string]bool
}

func newShebangProxy() *shebangProxy {
	return &shebangProxy{documents: map[string]bool{}, formatting: map[string]bool{}}
}

type message struct {
	ID     json.RawMessage `json:"id,omitempty"`
	Method string          `json:"method,omitempty"`
	Params json.RawMessage `json:"params,omitempty"`
	Result json.RawMessage `json:"result,omitempty"`
}

// fromEditor hides the shebang of documents the editor opens, or replaces as a whole.
func (p *shebangProxy) fromEditor(body []byte) []byte {
	var m message
	if json.Unmarshal(body, &m) != nil {
		return body
	}
	switch m.Method {
	case "textDocument/didOpen", "textDocument/didChange":
		return p.hideShebang(body, m.Params)
	case "textDocument/didClose":
		p.mutex.Lock()
		delete(p.documents, uriOf(m.Params))
		p.mutex.Unlock()
	case "textDocument/formatting":
		p.mutex.Lock()
		if p.documents[uriOf(m.Params)] {
			p.formatting[string(m.ID)] = true
		}
		p.mutex.Unlock()
	}
	return body
}

// fromServer gives formatting edits of a document with a shebang their shebang back.
func (p *shebangProxy) fromServer(body []byte) []byte {
	var m message
	if json.Unmarshal(body, &m) != nil || m.Method != "" || len(m.ID) == 0 {
		return body
	}
	p.mutex.Lock()
	formatting := p.formatting[string(m.ID)]
	delete(p.formatting, string(m.ID))
	p.mutex.Unlock()
	if !formatting {
		return body
	}
	var edits []map[string]any
	if json.Unmarshal(m.Result, &edits) != nil {
		return body
	}
	for _, edit := range edits {
		text, _ := edit["newText"].(string)
		if startsAtTheTop(edit) && strings.HasPrefix(text, "--") {
			edit["newText"] = "#!" + text[2:]
		}
	}
	return replaceField(body, "result", edits)
}

// hideShebang turns the shebang into a comment in an opened document, and in changes that
// replace a whole document. Edits of a range go through as they are: they apply to the comment
// as they would to the shebang.
func (p *shebangProxy) hideShebang(body []byte, raw json.RawMessage) []byte {
	var params map[string]any
	if json.Unmarshal(raw, &params) != nil {
		return body
	}
	texts := []any{params["textDocument"]}
	if changes, ok := params["contentChanges"].([]any); ok {
		texts = changes
	}
	hidden := false
	for _, entry := range texts {
		object, _ := entry.(map[string]any)
		text, isText := object["text"].(string)
		if _, ranged := object["range"]; isText && !ranged && strings.HasPrefix(text, "#!") {
			object["text"] = "--" + text[2:]
			hidden = true
		}
	}
	if !hidden {
		return body
	}
	p.mutex.Lock()
	p.documents[uriOf(raw)] = true
	p.mutex.Unlock()
	return replaceField(body, "params", params)
}

func startsAtTheTop(edit map[string]any) bool {
	textRange, _ := edit["range"].(map[string]any)
	start, _ := textRange["start"].(map[string]any)
	return start["line"] == float64(0) && start["character"] == float64(0)
}

func uriOf(params json.RawMessage) string {
	var p struct {
		TextDocument struct {
			URI string `json:"uri"`
		} `json:"textDocument"`
	}
	json.Unmarshal(params, &p)
	return p.TextDocument.URI
}

// replaceField re-encodes a message with one field replaced, keeping the others as they were.
func replaceField(body []byte, field string, value any) []byte {
	var fields map[string]json.RawMessage
	if json.Unmarshal(body, &fields) != nil {
		return body
	}
	encoded, err := json.Marshal(value)
	if err != nil {
		return body
	}
	fields[field] = encoded
	replaced, err := json.Marshal(fields)
	if err != nil {
		return body
	}
	return replaced
}
