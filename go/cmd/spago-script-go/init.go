package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"unicode"
)

// manifestMarker starts the spago.yaml that init writes, so that init knows it may replace it.
const manifestMarker = "# Written by spago-script-go init"

// initFolder makes dir a script folder: Iris's language server, started by the editor in dir, sees
// Script.Prelude, the Go bindings and their dependencies, and the scripts at the top of dir.
//
// The scripts aren't in a package (Spago packages only have src and test). Iris still checks every
// file the editor opens against the workspace's packages, which is all a script needs. The
// workspace's own package depends on what scripts can import; the prelude and the Go bindings come
// from the project the scripts compile in.
func initFolder(dir string, server string) error {
	dir, err := filepath.Abs(dir)
	if err != nil {
		return err
	}
	project, err := materializedProject()
	if err != nil {
		return err
	}
	if err := writeManifest(dir, project); err != nil {
		return err
	}
	renamed, err := renameMainModules(dir)
	if err != nil {
		return err
	}
	for _, rename := range renamed {
		fmt.Printf("%s: module Main is now module %s\n", rename.file, rename.module)
	}
	if err := writeEditorSettings(dir, server); err != nil {
		return err
	}
	if err := fetchDependencies(dir); err != nil {
		return err
	}
	fmt.Printf("%s is a script folder. Open it in VS Code with the purescript-iris extension.\n", dir)
	return nil
}

func materializedProject() (string, error) {
	cache, err := cacheDir()
	if err != nil {
		return "", err
	}
	project := filepath.Join(cache, "project", projectKey())
	if err := os.MkdirAll(project, 0o755); err != nil {
		return "", err
	}
	unlock, err := lock(filepath.Join(project, ".lock"))
	if err != nil {
		return "", err
	}
	defer unlock()
	return project, materialize(project)
}

// writeManifest writes the workspace: the scripts project's manifest with the prelude and the Go
// bindings as local packages. It leaves alone a spago.yaml that init didn't write.
func writeManifest(dir string, project string) error {
	path := filepath.Join(dir, "spago.yaml")
	existing, err := os.ReadFile(path)
	if err == nil && !strings.HasPrefix(string(existing), manifestMarker) {
		return fmt.Errorf("%s already has a spago.yaml, so it isn't a script folder", dir)
	}
	if err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	return os.WriteFile(path, []byte(manifest(project)), 0o644)
}

func manifest(project string) string {
	scriptsManifest, err := bundle.ReadFile("bundle/spago.yaml")
	if err != nil {
		panic("the bundle has no spago.yaml; run build.sh")
	}
	return manifestMarker + "; run it again after updating spago-script-go.\n" +
		strings.Replace(string(scriptsManifest), "name: script\n", "name: scripts\n", 1) +
		"  extraPackages:\n" +
		"    spago-script-go:\n      path: " + filepath.Join(project, "prelude") + "\n" +
		"    golang:\n      path: " + filepath.Join(project, "golang") + "\n"
}

type rename struct {
	file   string
	module string
}

var mainHeader = regexp.MustCompile(`(?m)^(\s*module\s+)Main(\s+where\b)`)

// renameMainModules names every `module Main` script after its file, so that the scripts of one
// folder don't clash.
func renameMainModules(dir string) ([]rename, error) {
	files, err := filepath.Glob(filepath.Join(dir, "*.purs"))
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	var renamed []rename
	for _, file := range files {
		source, err := os.ReadFile(file)
		if err != nil {
			return nil, err
		}
		header := mainHeader.FindIndex(source)
		module := moduleName(file)
		if header == nil || module == "Main" {
			continue
		}
		replaced := mainHeader.ReplaceAll(source[:header[1]], []byte("${1}"+module+"${2}"))
		if err := writeKeepingMode(file, append(replaced, source[header[1]:]...)); err != nil {
			return nil, err
		}
		renamed = append(renamed, rename{file: filepath.Base(file), module: module})
	}
	return renamed, nil
}

// moduleName is the module a script file goes by: `list-files.purs` is ListFiles.
func moduleName(file string) string {
	base := strings.TrimSuffix(filepath.Base(file), filepath.Ext(file))
	words := strings.FieldsFunc(base, func(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) })
	var name strings.Builder
	for _, word := range words {
		runes := []rune(word)
		name.WriteString(strings.ToUpper(string(runes[0])) + string(runes[1:]))
	}
	if name.Len() == 0 || !unicode.IsLetter([]rune(name.String())[0]) {
		return "Script" + name.String()
	}
	return name.String()
}

func writeKeepingMode(path string, contents []byte) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	return os.WriteFile(path, contents, info.Mode().Perm())
}

// writeEditorSettings points the purescript-iris extension at `spago-script-go lsp`, and stops
// ide-purescript from starting a purs IDE server, which doesn't know the scripts.
func writeEditorSettings(dir string, server string) error {
	path := filepath.Join(dir, ".vscode", "settings.json")
	settings := map[string]any{}
	if existing, err := os.ReadFile(path); err == nil {
		if err := json.Unmarshal(existing, &settings); err != nil {
			return fmt.Errorf("can't update %s (%w); set iris.client.serverPath to %s yourself", path, err, server)
		}
	} else if !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	settings["iris.client.serverPath"] = server
	settings["purescript.autoStartPscIde"] = false
	excluded, _ := settings["files.exclude"].(map[string]any)
	if excluded == nil {
		excluded = map[string]any{}
	}
	excluded[".spago"] = true
	settings["files.exclude"] = excluded
	contents, err := json.MarshalIndent(settings, "", "\t")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, append(contents, '\n'), 0o644)
}

// fetchDependencies runs `spago fetch`, which the language server would otherwise do when it
// starts.
func fetchDependencies(dir string) error {
	if _, err := exec.LookPath("spago"); err != nil {
		fmt.Println("Spago isn't on your PATH; the language server needs it to fetch dependencies.")
		return nil
	}
	return quietly(dir, "spago", "fetch")
}
