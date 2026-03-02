"""Module extension that provides the OSS CAD Suite as an external repository.

All version-specific details (URL, SHA-256) are pinned here so downstream
modules only need:

    oss_cad_suite = use_extension("@ecos-bazel//rules:oss_cad_suite.bzl", "oss_cad_suite")
    use_repo(oss_cad_suite, "oss_cad_suite")
"""

load("//rules:download_and_extract.bzl", "download_and_extract")

_VERSION = "2026-01-22"
_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/{version}/oss-cad-suite-linux-x64-{tag}.tgz".format(
    version = _VERSION,
    tag = _VERSION.replace("-", ""),
)
_SHA256 = "b536961118dd7497707752d9fd45714c5f6dacd150e02387bac4f75c28a16567"

def _oss_cad_suite_impl(_mctx):
    download_and_extract(
        name = "oss_cad_suite",
        urls = [_URL],
        sha256 = _SHA256,
        build_file_template = "//rules:oss_cad_suite.BUILD.bazel",
    )

oss_cad_suite = module_extension(
    implementation = _oss_cad_suite_impl,
)
