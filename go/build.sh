#!/usr/bin/env bash
# Builds the spago-script-go binary with Script.Prelude for Go embedded.
#
#   ./build.sh [OUTPUT]     # default: ./bin/spago-script-go
#
# Environment: PURESCRIPT_GOLANG (a purescript-golang checkout, default ../../purescript-golang).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOLANG="${PURESCRIPT_GOLANG:-$HERE/../../purescript-golang}"
CLI="$HERE/cmd/spago-script-go"
BUNDLE="$CLI/bundle"
OUTPUT="${1:-$HERE/bin/spago-script-go}"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/prelude" "$BUNDLE/golang" "$BUNDLE/out"
cp -RL "$HERE/src" "$BUNDLE/prelude/src"
cp -RL "$GOLANG/src" "$BUNDLE/golang/src"
python3 - "$HERE/spago.yaml" "$GOLANG/spago.yaml" "$BUNDLE" <<'PY'
import sys

def package_only(path):
    """The package section of a spago.yaml, without its tests or workspace."""
    kept, skipping = [], False
    for line in open(path).read().splitlines():
        if line.startswith("workspace:"):
            break
        if line.startswith("  test:"):
            skipping = True
            continue
        if skipping and line.startswith("    "):
            continue
        skipping = False
        kept.append(line)
    return "\n".join(kept) + "\n"

def dependencies(path):
    names, inside = [], False
    for line in open(path).read().splitlines():
        if line.startswith("  dependencies:"):
            inside = True
            continue
        if inside and line.startswith("    - "):
            names.append(line[6:].split(":")[0].strip())
        elif inside:
            break
    return names

prelude, golang, bundle = sys.argv[1:]
open(f"{bundle}/prelude/spago.yaml", "w").write(package_only(prelude))
open(f"{bundle}/golang/spago.yaml", "w").write(package_only(golang))
registry = next(line.split(":")[1].strip() for line in open(prelude) if line.strip().startswith("registry:"))
script_dependencies = sorted(set(dependencies(prelude)) | {"spago-script-go"})
open(f"{bundle}/spago.yaml", "w").write(
    "package:\n  name: script\n  dependencies:\n"
    + "".join(f"    - {name}\n" for name in script_dependencies)
    + f"workspace:\n  packageSet:\n    registry: {registry}\n")
PY
cat >"$BUNDLE/out/go.mod.template" <<'MOD'
module spago-script

go 1.27.0

require (
	github.com/i-am-the-slime/iris-go v0.1.1
	modernc.org/sqlite v1.62.0
)
MOD
mkdir -p "$(dirname "$OUTPUT")"
(cd "$CLI" && go build -o "$OUTPUT" .)
echo "built $OUTPUT"
