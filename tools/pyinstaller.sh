#!/usr/bin/env bash
# Bazel-managed PyInstaller wrapper
set -euo pipefail

# Find Python interpreter: explicit env > venv > system
if [[ -n "${PYTHON_INTERPRETER:-}" ]]; then
    PYTHON="$PYTHON_INTERPRETER"
elif [[ -x ".venv/bin/python" ]]; then
    PYTHON=".venv/bin/python"
else
    PYTHON="python3"
fi

# Run PyInstaller with all arguments
exec "$PYTHON" -m PyInstaller "$@"
