# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ecos-bazel` is a Bazel rules library providing generic utilities for Python/C++ packaging, EDA toolchain management, and repository rules. Designed for ECOS (chip design automation) but portable to any EDA/scientific computing project.

## Commands

```bash
# Format Bazel files
nix shell nixpkgs#bazel-buildtools -c buildifier -r .

# Sync dependencies (after MODULE.bazel changes)
nix shell nixpkgs#bazel_8 -c bazel mod deps

# Build targets
nix shell nixpkgs#bazel_8 -c bazel build //...

# Test (if test targets exist)
nix shell nixpkgs#bazel_8 -c bazel test //...
```

## Architecture

**Module Structure:**
```
rules/              # Starlark rules and module extensions
├── *_pdk.bzl       # Module extensions for EDA dependencies
├── download_and_extract.bzl  # Core repository rule
├── python_packaging.bzl       # PyInstaller/c++ bundling rules
├── local_source_repo.bzl      # Local source import (strips BUILD files)
└── uv_export.bzl             # uv.lock → requirements.txt generator

tools/             # Executable helpers
├── pyinstaller.sh         # PyInstaller wrapper (finds Python)
├── autopatch-runtime.sh   # C++ runtime bundling script
└── auto-patchelf/         # Python auto-patchelf tool
```

**Module Extensions Pattern:**
All EDA dependencies (PDK, OSS CAD Suite, patchelf) follow the same pattern:
1. `_VERSION`, `_URL`, `_SHA256` pinned at top of `.bzl`
2. Load `download_and_extract` helper
3. `module_extension` implementation calls `download_and_extract()`
4. Downstream usage: `use_extension("@ecos-bazel//rules:foo.bzl", "foo")` + `use_repo(foo, "foo")`

**Key Abstractions:**

- `download_and_extract`: Universal archive downloader with optional post-setup commands and BUILD generation via `build_file_template` or `build_file_content`
- `python_pyinstaller_bundle`: Bundles Python apps via PyInstaller, supports runtime bundle extraction
- `cpp_runtime_bundle`: Bundles C++ .so files with auto-patchelf RPATH patching (`$ORIGIN:$ORIGIN/lib`)
- `local_source_repo`: Imports local sources while stripping BUILD/WORKSPACE to prevent package boundary issues with `cmake()` globs

## Important Patterns

**Adding New Module Extensions:**
```python
# rules/new_tool.bzl
load("//rules:download_and_extract.bzl", "download_and_extract")

_VERSION = "x.y.z"
_URL = "https://..."
_SHA256 = "..."

def _new_tool_impl(_mctx):
    download_and_extract(
        name = "new_tool",
        urls = [_URL],
        sha256 = _SHA256,
        build_file_template = "//rules:new_tool.BUILD.bazel",
    )

new_tool = module_extension(implementation = _new_tool_impl)
```

**BUILD File Templates:**
- Use `ctx.template("BUILD.bazel", ctx.attr.build_file_template, substitutions={})` in repository rules
- Template files live in `rules/*.BUILD.bazel` and are exported via `rules/BUILD.bazel`

**Runtime Bundling Gotchas:**
- PyInstaller bundle extraction must use `--keep-directory-symlink` to preserve Bazel execroot symlinks
- C++ RPATH uses `$ORIGIN` for relative library lookup
- `autopatch-runtime.sh` copies .so files and runs auto-patchelf before creating tarball

**Python Tool Discovery:**
- `tools/pyinstaller.sh` finds Python via `$PYTHON_INTERPRETER` → `.venv/bin/python` → `python3`
- Never hardcode Python paths in sh_binary rules

## Dependencies

- `rules_python` 1.7.0 - Python toolchain/pip support
- `rules_shell` 0.6.1 - Shell execution rules
- `uv` - Required for `uv_export` rule (must be in PATH)
- `nix-shell` - Dev environment with buildifier (optional but recommended)
