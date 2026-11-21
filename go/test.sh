#!/usr/bin/env bash
# Runs the Go flavour's tests: the Script.Prelude specs, the CLI tests and the prompt tests.
#
#   go/test.sh
#
# Environment: IRIS (the iris binary), IRIS_GO (a local iris-go checkout to build against).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IRIS="${IRIS:-iris}"
OUT="$HERE/out"

echo "== Script.Prelude specs"
mkdir -p "$OUT"
{
  echo "module spago-script-go-test"
  echo
  echo "go 1.27.0"
  echo
  echo "require ("
  echo "	github.com/i-am-the-slime/iris-go v0.1.0"
  echo "	modernc.org/sqlite v1.62.0"
  echo ")"
  if [ -n "${IRIS_GO:-}" ]; then
    echo
    echo "replace github.com/i-am-the-slime/iris-go => $IRIS_GO"
  fi
} >"$OUT/go.mod"
(cd "$HERE" && "$IRIS" go --entry Test.Main.main "$OUT" >/dev/null)
(cd "$OUT" && GOFLAGS=-mod=mod go build -o spec-runner .)
(cd "$HERE" && "$OUT/spec-runner")

echo "== CLI"
"$HERE/build.sh" >/dev/null
(cd "$HERE/cmd/spago-script-go" && IRIS="$IRIS" go test -count=1 .)

echo "== prompts"
IRIS="$IRIS" "$HERE/test/pty/run" "$HERE/bin/spago-script-go"
