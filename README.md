# ECOS Bazel Rules

Generic Bazel rules and utilities for Python and C++ packaging, designed for EDA and scientific computing projects.

## Features

- **Repository Rules**: Generic rules for downloading archives and importing local sources
- **Python Packaging**: PyInstaller-based bundling with runtime dependency management
- **C++ Runtime Bundling**: Automatic RPATH patching and dependency bundling with auto-patchelf
- **Module Extensions**: Pre-configured dependencies for EDA workflows
  - ICSprout55 PDK (Process Design Kit)
  - OSS CAD Suite (Yosys, nextpnr, and other open-source EDA tools)
  - Patchelf (ELF binary modification tool)
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

# Use module extensions
icsprout55_pdk = use_extension("@ecos-bazel//rules:icsprout55_pdk.bzl", "icsprout55_pdk")
icsprout55_pdk.configure(enable_proxy = True)  # Optional: enable proxy for download
use_repo(icsprout55_pdk, "icsprout55_pdk")

oss_cad_suite = use_extension("@ecos-bazel//rules:oss_cad_suite.bzl", "oss_cad_suite")
use_repo(oss_cad_suite, "oss_cad_suite")

patchelf = use_extension("@ecos-bazel//rules:patchelf.bzl", "patchelf")
use_repo(patchelf, "patchelf")
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

### Module Extensions

#### ICSprout55 PDK

Process Design Kit for digital synthesis:

```python
icsprout55_pdk = use_extension("@ecos-bazel//rules:icsprout55_pdk.bzl", "icsprout55_pdk")
icsprout55_pdk.configure(enable_proxy = True)  # Optional: enable proxy for download
use_repo(icsprout55_pdk, "icsprout55_pdk")

# Use in BUILD files
cc_library(
    name = "my_design",
    srcs = ["my_design.v"],
    deps = ["@icsprout55_pdk//:cells"],
)
```

**Configuration:**
- `enable_proxy`: If `True`, uses proxy for downloading PDK files (default: `False`)

**Version:** Commit `e696e09` (pinned)

#### OSS CAD Suite

Open-source EDA tools including Yosys, nextpnr, and more:

```python
oss_cad_suite = use_extension("@ecos-bazel//rules:oss_cad_suite.bzl", "oss_cad_suite")
use_repo(oss_cad_suite, "oss_cad_suite")

# Use in BUILD files
sh_binary(
    name = "synthesize",
    srcs = ["synthesize.sh"],
    data = ["@oss_cad_suite//:yosys"],
)
```

**Version:** 2026-01-22 (pinned)

**Included Tools:**
- Yosys (Verilog synthesis)
- nextpnr (FPGA place & route)
- OpenROAD (ASIC physical design)
- And more...

#### Patchelf

ELF binary modification tool for RPATH patching:

```python
patchelf = use_extension("@ecos-bazel//rules:patchelf.bzl", "patchelf")
use_repo(patchelf, "patchelf")

# Use in BUILD files
# @patchelf//:bin/patchelf
```

**Version:** 0.18.0 (pinned)

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
