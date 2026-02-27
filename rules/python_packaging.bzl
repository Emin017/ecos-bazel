"""Generic Python packaging rules using PyInstaller."""

def python_pyinstaller_bundle(
        name,
        spec_file,
        srcs = [],
        runtime_bundle = None,
        output_name = None,
        pyinstaller = "@ecos-bazel//tools:pyinstaller",
        visibility = None):
    """Bundle Python application using PyInstaller.

    Args:
        name: Target name
        spec_file: PyInstaller .spec file
        srcs: Additional source files needed for bundling
        runtime_bundle: Optional runtime dependencies tarball to extract
        output_name: Output binary name (defaults to name)
        pyinstaller: PyInstaller tool target
        visibility: Target visibility
    """
    output_name = output_name or name

    all_srcs = [spec_file] + srcs
    if runtime_bundle:
        all_srcs.append(runtime_bundle)

    cmd_parts = ["set -euo pipefail"]

    if runtime_bundle:
        cmd_parts.append("tar -xf $(location {}) -C .".format(runtime_bundle))

    cmd_parts.extend([
        "$(location {}) $(location {})".format(pyinstaller, spec_file),
        "  --clean",
        "  --noconfirm",
        "  --distpath \"$(@D)/{}\"".format(name),
        "  --workpath \"$(@D)/{}_work\"".format(name),
    ])

    native.genrule(
        name = name,
        srcs = all_srcs,
        tools = [pyinstaller],
        outs = ["{}/{}".format(name, output_name)],
        tags = ["local", "no-sandbox"],
        cmd = "\n".join(cmd_parts),
        visibility = visibility,
    )

def cpp_runtime_bundle(
        name,
        cmake_target,
        dest_bin_dir,
        dest_lib_dir,
        so_pattern = "*.so",
        autopatch_script = "@ecos-bazel//tools:autopatch_runtime",
        auto_patchelf_bin = "@ecos-bazel//tools/auto-patchelf:auto_patchelf",
        patchelf = "@patchelf//:bin/patchelf",
        visibility = None):
    """Bundle C++ runtime with auto-patchelf.

    Args:
        name: Target name
        cmake_target: CMake build target
        dest_bin_dir: Destination directory for binaries (relative to bundle root)
        dest_lib_dir: Destination directory for libraries (relative to bundle root)
        so_pattern: Pattern for .so files to copy
        autopatch_script: Auto-patch script target
        auto_patchelf_bin: Auto-patchelf tool target
        patchelf: Patchelf binary target
        visibility: Target visibility
    """
    native.genrule(
        name = name,
        srcs = [cmake_target],
        tools = [autopatch_script, auto_patchelf_bin, patchelf],
        outs = ["{}/{}.tar".format(name, name)],
        tags = ["local", "no-sandbox"],
        cmd = """
            set -euo pipefail

            BUNDLE_ROOT="$(@D)/{name}_stage"
            DEST_BIN="$$BUNDLE_ROOT/{dest_bin_dir}"
            DEST_LIB="$$BUNDLE_ROOT/{dest_lib_dir}"
            mkdir -p "$$DEST_BIN" "$$DEST_LIB"

            # Derive cmake output root
            for _loc in $(locations {cmake_target}); do CMAKE_DIR=$$(dirname "$$_loc"); break; done

            # Copy .so files from cmake output
            find "$$CMAKE_DIR/lib" -name '{so_pattern}' -exec cp -f {{}} "$$DEST_BIN/" \\;
            chmod u+w "$$DEST_BIN"/{so_pattern}

            # Run autopatch
            export PATH="$$(dirname $(location {patchelf})):$$PATH"
            # auto_patchelf is a py_binary that expands to multiple files, use first one
            export AUTO_PATCHELF_BIN="$$(echo $(locations {auto_patchelf_bin}) | awk '{{print $$1}}')"
            bash $(location {autopatch_script}) \\
                --dest-bin-dir "$$DEST_BIN" \\
                --dest-lib-dir "$$DEST_LIB" \\
                --ecc-py "$$DEST_BIN" \\
                --runtime-lib-path "$$CMAKE_DIR/lib"

            tar -cf $@ -C "$$BUNDLE_ROOT" .
        """.format(
            name = name,
            cmake_target = cmake_target,
            dest_bin_dir = dest_bin_dir,
            dest_lib_dir = dest_lib_dir,
            so_pattern = so_pattern,
            autopatch_script = autopatch_script,
            auto_patchelf_bin = auto_patchelf_bin,
            patchelf = patchelf,
        ),
        visibility = visibility,
    )
