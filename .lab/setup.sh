#!/bin/sh
# Installs the Lab Activity Monitor into the VS Code that opened this folder (macOS / Linux).
# Run automatically by .vscode/tasks.json when the folder is opened in a trusted window.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
exec_path="$1"

lab_id=$(sed -n 's/.*"labId"[^"]*"\([^"]*\)".*/\1/p' "$here/lab.json")
expiry_hours=$(sed -n 's/.*"expiryHours"[^0-9]*\([0-9]*\).*/\1/p' "$here/lab.json")
state_dir="${WEBLAB_STATE_DIR:-$HOME/.weblab}"
marker="$state_dir/$lab_id.json"

# The monitor removes itself after the lab period; don't reinstall it after that.
if [ -f "$marker" ]; then
    first=$(sed -n 's/.*"firstSeenEpoch"[^0-9]*\([0-9]*\).*/\1/p' "$marker")
    if [ $(( $(date +%s) - first )) -ge $(( expiry_hours * 3600 )) ]; then
        echo "Lab period has ended: Lab Activity Monitor is not reinstalled."
        exit 0
    fi
fi

# Find the CLI of the VS Code that is running this task
dir="$(dirname "$exec_path")"
cli=""
for candidate in "$dir/bin/code" "$dir/../Resources/app/bin/code" "$(command -v code || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then cli="$candidate"; break; fi
done
[ -z "$cli" ] && { echo "VS Code command line not found"; exit 1; }

if [ -n "$LAB_EXTENSIONS_DIR" ]; then
    "$cli" --install-extension "$here/lab-activity-monitor.vsix" --extensions-dir "$LAB_EXTENSIONS_DIR"
else
    "$cli" --install-extension "$here/lab-activity-monitor.vsix"
fi
