"""Module extension that provides patchelf as an external repository.

All version-specific details (URL, SHA-256) are pinned here so downstream
modules only need:

    patchelf = use_extension("@ecos-bazel//rules:patchelf.bzl", "patchelf")
    use_repo(patchelf, "patchelf")
"""

load("//rules:download_and_extract.bzl", "download_and_extract")

_VERSION = "0.18.0"
_URL = "https://github.com/NixOS/patchelf/releases/download/{version}/patchelf-{version}-x86_64.tar.gz".format(version = _VERSION)
_SHA256 = "ce84f2447fb7a8679e58bc54a20dc2b01b37b5802e12c57eece772a6f14bf3f0"

def _patchelf_impl(_mctx):
    download_and_extract(
        name = "patchelf",
        urls = [_URL],
        sha256 = _SHA256,
        build_file_content = """exports_files(["bin/patchelf"])""",
    )

patchelf = module_extension(
    implementation = _patchelf_impl,
)
