# ECOS Bazel Rules

Generic Bazel rules and utilities for Python and C++ packaging, designed for EDA and scientific computing projects.

## Features

- **Repository Rules**: Generic rules for downloading archives and importing local sources
- **Python Packaging**: PyInstaller-based bundling with runtime dependency management
- **C++ Runtime Bundling**: Automatic RPATH patching and dependency bundling with auto-patchelf
- **Portable**: Parameterized paths work across different project structures

## Usage

### In your MODULE.bazel

```python
bazel_dep(name = "ecos-bazel", version = "0.1.0")

# Or use local override during development
local_path_override(
    module_name = "ecos-bazel",
    path = "path/to/ecos-bazel-rules",
)
```

### Repository Rules

#### download_and_extract

Download and extract archives with optional post-setup commands:

```python
load("@ecos-bazel//rules:download_and_extract.bzl", "download_and_extract")

download_and_extract(
    name = "my_dependency",
    urls = ["https://example.com/dep.tar.gz"],
    sha256 = "abc123...",
    strip_prefix = "dep-1.0.0",
    post_setup_cmds = ["make install"],
    environment = {"PREFIX": "/usr/local"},
    build_file_template = "//templates:dep.BUILD.bazel",
)
```

#### local_source_repo

Import local source directories with BUILD file stripping:

```python
load("@ecos-bazel//rules:local_source_repo.bzl", "local_source_repo")

local_source_repo(
    name = "my_local_src",
    path = "third_party/my_src",
)
```

### Python Packaging

Bundle Python applications with PyInstaller:

```python
load("@ecos-bazel//rules:python_packaging.bzl", "python_pyinstaller_bundle")

python_pyinstaller_bundle(
    name = "my_app",
    spec_file = "my_app.spec",
    srcs = [
        "//src:python_sources",
        "pyproject.toml",
    ],
    runtime_bundle = "//third_party:runtime_bundle",
    output_name = "my_app",
)
```

### C++ Runtime Bundling

Bundle C++ libraries with automatic dependency resolution:

```python
load("@ecos-bazel//rules:python_packaging.bzl", "cpp_runtime_bundle")

cpp_runtime_bundle(
    name = "runtime_bundle",
    cmake_target = ":my_cmake_lib",
    dest_bin_dir = "bin",
    dest_lib_dir = "lib",
    so_pattern = "*.so",
)
```

## API Reference

### python_pyinstaller_bundle

**Parameters:**
- `name`: Target name
- `spec_file`: PyInstaller .spec file
- `srcs`: Additional source files needed for bundling
- `runtime_bundle`: Optional runtime dependencies tarball to extract
- `output_name`: Output binary name (defaults to name)
- `pyinstaller`: PyInstaller tool target (default: `@ecos-bazel//tools:pyinstaller`)
- `visibility`: Target visibility

### cpp_runtime_bundle

**Parameters:**
- `name`: Target name
- `cmake_target`: CMake build target
- `dest_bin_dir`: Destination directory for binaries (relative to bundle root)
- `dest_lib_dir`: Destination directory for libraries (relative to bundle root)
- `so_pattern`: Pattern for .so files to copy (default: `*.so`)
- `autopatch_script`: Auto-patch script target (default: `@ecos-bazel//tools:autopatch_runtime`)
- `auto_patchelf_bin`: Auto-patchelf tool target (default: `@ecos-bazel//tools/auto-patchelf:auto_patchelf`)
- `patchelf`: Patchelf binary target (default: `@patchelf//:bin/patchelf`)
- `visibility`: Target visibility

## License

Apache 2.0
