"""Module extension that provides appimagetool as an external repository.

All version-specific details (URL, SHA-256) are pinned here so downstream
modules only need:

    appimage_tool = use_extension("@ecos-bazel//rules:appimage-tool.bzl", "appimage_tool")
    use_repo(appimage_tool, "appimagetool_x86_64_linux")
"""

_URL = "https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
_SHA256 = "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"

_ARTIFACTS = {
    # "amd64" on Linux/Windows, "x86_64" on macOS Intel — same architecture
    "amd64": {
        "url": _URL,
        "sha256": _SHA256,
    },
    "x86_64": {
        "url": _URL,
        "sha256": _SHA256,
    },
}

def _appimagetool_repo_impl(ctx):
    if ctx.os.name != "linux":
        fail("appimagetool: only supported on Linux (AppImage is Linux-only), got: " + ctx.os.name)
    arch = ctx.os.arch
    if arch not in _ARTIFACTS:
        fail("appimagetool: unsupported arch '{}', supported: {}".format(arch, _ARTIFACTS.keys()))
    artifact = _ARTIFACTS[arch]
    ctx.download(
        url = artifact["url"],
        output = "appimagetool",
        sha256 = artifact["sha256"],
        executable = True,
    )
    ctx.file("BUILD.bazel", 'exports_files(["appimagetool"])\n')

_appimagetool_repo = repository_rule(
    implementation = _appimagetool_repo_impl,
)

def _appimage_tool_impl(_mctx):
    _appimagetool_repo(name = "appimagetool_x86_64_linux")

appimage_tool = module_extension(
    implementation = _appimage_tool_impl,
)
