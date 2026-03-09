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

# Verify PyInstaller is available before running
if ! "$PYTHON" -c "import PyInstaller" 2>/dev/null; then
    echo "ERROR: PyInstaller not found in Python at: $PYTHON" >&2
    echo "" >&2
    echo "Please set up the virtual environment first:" >&2
    echo "  make dev       # install dependencies" >&2
    echo "  make build     # build with venv auto-configured" >&2
    echo "" >&2
    echo "Or set PYTHON_INTERPRETER to a Python with PyInstaller installed." >&2
    exit 1
fi

# Run PyInstaller with all arguments
exec "$PYTHON" -m PyInstaller "$@"
