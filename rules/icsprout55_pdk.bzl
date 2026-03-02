"""Module extension that provides the icsprout55 PDK as an external repository.

All version-specific details (URL, SHA-256, strip prefix) are pinned here so
downstream modules only need:

    icsprout55_pdk = use_extension("@ecos-bazel//rules:icsprout55_pdk.bzl", "icsprout55_pdk")
    icsprout55_pdk.configure(enable_proxy = True)  # Optional: enable proxy for download
    use_repo(icsprout55_pdk, "icsprout55_pdk")
"""

load("//rules:download_and_extract.bzl", "download_and_extract")

_COMMIT = "e696e093129ca2212487aa169af74d06ebd86eb6"
_URL = "https://github.com/openecos-projects/icsprout55-pdk/archive/{commit}.tar.gz".format(commit = _COMMIT)
_SHA256 = "105790f050fe27f7f2d79536533837a37b290a2f97e8cfca98a93cc28c31f759"
_STRIP_PREFIX = "icsprout55-pdk-{commit}".format(commit = _COMMIT)

def _icsprout55_pdk_impl(mctx):
    # Read configuration from tags
    enable_proxy = False
    for mod in mctx.modules:
        for config in mod.tags.configure:
            enable_proxy = config.enable_proxy

    # Determine post-setup commands based on configuration
    if enable_proxy:
        post_setup_cmds = ["USE_PROXY=true make unzip"]
    else:
        post_setup_cmds = ["make unzip"]

    download_and_extract(
        name = "icsprout55_pdk",
        urls = [_URL],
        sha256 = _SHA256,
        strip_prefix = _STRIP_PREFIX,
        post_setup_cmds = post_setup_cmds,
        environment = {"TOOL": "curl"},
        build_file_template = "//rules:pdk_repo.BUILD.bazel",
    )

_configure = tag_class(
    attrs = {
        "enable_proxy": attr.bool(
            default = False,
            doc = "If True, use 'make download USE_PROXY=true' instead of 'make unzip'",
        ),
    },
)

icsprout55_pdk = module_extension(
    implementation = _icsprout55_pdk_impl,
    tag_classes = {
        "configure": _configure,
    },
)
