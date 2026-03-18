#!/usr/bin/env bash
# Check development environment via DSC v3 configuration.
# Outputs a JSON summary suitable for Claude Code SessionStart hooks.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSC_FILE="$SCRIPT_DIR/algt-devenv.dsc.yaml"

# Find dsc executable
if command -v dsc &>/dev/null; then
    DSC_CMD=dsc
elif [ -x "/c/Program Files/dsc/dsc.exe" ]; then
    DSC_CMD="/c/Program Files/dsc/dsc.exe"
elif [ -x "/mnt/c/Program Files/dsc/dsc.exe" ]; then
    DSC_CMD="/mnt/c/Program Files/dsc/dsc.exe"
else
    echo '{"systemMessage":"Dev env check: dsc not found on PATH"}'
    exit 0
fi

# Run dsc config test
OUTPUT=$("$DSC_CMD" config test --file "$DSC_FILE" 2>/dev/null)
EXIT_CODE=$?

if [ -z "$OUTPUT" ]; then
    echo '{"systemMessage":"Dev env check: no output from dsc"}'
    exit 0
fi

# Find a working python interpreter
find_python() {
    # Try pyenv versions first (known-good on this system)
    for ver in "$HOME/.pyenv/pyenv-win/versions"/*/python.exe; do
        [ -x "$ver" ] && echo "$ver" && return 0
    done
    # Try system python (skip Windows Store stubs by testing --version)
    for cmd in python3 python; do
        if command -v "$cmd" &>/dev/null && "$cmd" --version &>/dev/null; then
            echo "$cmd" && return 0
        fi
    done
    return 1
}

# Parse JSON output — try jq, then python, then bare fallback
if command -v jq &>/dev/null; then
    TOTAL=$(echo "$OUTPUT" | jq '.results | length')
    ISSUES=$(echo "$OUTPUT" | jq -r '
        [.results[] | select(.result.inDesiredState == false) |
         .name + " (" + ((.result.differingProperties // []) | join(", ")) + ")"]
        | if length > 0 then
            "Dev env: \(length) issue(s):\n" + (map("  - " + .) | join("\n"))
          else
            empty
          end
    ')
    if [ -z "$ISSUES" ]; then
        MSG="Dev env: all $TOTAL resources OK"
    else
        MSG="$ISSUES"
    fi
elif PY=$(find_python); then
    MSG=$("$PY" -c "
import json, sys
data = json.loads(sys.stdin.read())
results = data.get('results', [])
issues = []
for r in results:
    name = r.get('name', '?')
    res = r.get('result', {})
    if not res.get('inDesiredState', True):
        diff = res.get('differingProperties', [])
        issues.append('  - ' + name + ' (' + ', '.join(diff) + ')' if diff else '  - ' + name + ' (not in desired state)')
if issues:
    print('Dev env: ' + str(len(issues)) + ' issue(s):\n' + '\n'.join(issues))
else:
    print('Dev env: all ' + str(len(results)) + ' resources OK')
" <<< "$OUTPUT")
else
    # Bare fallback: just report dsc exit code
    if [ $EXIT_CODE -eq 0 ]; then
        MSG="Dev env: dsc test passed"
    else
        MSG="Dev env: dsc test reported issues (install jq or python for details)"
    fi
fi

# Escape for JSON output
MSG=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '|' | sed 's/|/\\n/g')
echo "{\"systemMessage\":\"$MSG\"}"
