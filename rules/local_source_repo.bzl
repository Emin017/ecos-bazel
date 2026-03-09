"""Repository rule for importing local source tree without BUILD/WORKSPACE files.

This rule is designed for importing local source trees that contain third-party
dependencies with their own BUILD files that would create package boundaries and
block glob traversal in cmake() or other build rules.

The rule:
1. Copies the local source directory
2. Removes BUILD and WORKSPACE files to prevent package boundary issues
3. Removes files with non-printable characters (Bazel label restriction)
4. Generates a minimal BUILD file for the repository

This allows cmake() rules to glob across the entire source tree without being blocked
by nested BUILD files.
"""

def _local_source_repo_impl(ctx):
    # Handle both absolute and relative paths
    path_str = ctx.attr.path
    if path_str.startswith("/"):
        # Absolute path
        src_path = path_str
    else:
        # Relative path - resolve from workspace_root
        # ctx.workspace_root gives us the path to the main workspace
        workspace_root = str(ctx.workspace_root)
        src_path = workspace_root + "/" + path_str

    # Watch the source tree so Bazel only re-fetches when contents change,
    # instead of re-fetching on every build (which `local = True` would do).
    ctx.watch_tree(ctx.path(src_path))

    result = ctx.execute(
        ["bash", "-c", """
            set -euo pipefail
            if [ ! -d "{src}" ]; then
                echo "ERROR: Source directory does not exist: {src}" >&2
                exit 1
            fi
            cp -a "{src}/." .
            find . -type f \\( \
                -name BUILD \
                -o -name BUILD.bazel \
                -o -name WORKSPACE \
                -o -name WORKSPACE.bazel \
            \\) -delete
            # Remove files with non-printable chars in names (Bazel label restriction).
            find . -type f | LC_ALL=C grep '[^[:print:]/]' | while IFS= read -r f; do
                rm -f "$f"
            done
        """.format(src = src_path)],
        quiet = False,
    )

    if result.return_code != 0:
        fail("Failed to copy source directory: " + result.stderr)

    # Use template BUILD file
    ctx.template(
        "BUILD.bazel",
        Label("@ecos-bazel//rules:local_source_repo.BUILD.bazel"),
    )

local_source_repo = repository_rule(
    implementation = _local_source_repo_impl,
    attrs = {
        "path": attr.string(
            mandatory = True,
            doc = "Path to the local source directory (absolute or workspace-relative).",
        ),
    },
    local = False,
    doc = "Imports local source tree, stripping BUILD/WORKSPACE files for cmake() compatibility.",
)
