"""Module extension that provides the OSS CAD Suite as external repositories.

Two repos are created:
  - @oss_cad_suite         Full (unpruned) suite — all tools available.
  - @oss_cad_suite_pruned  Pruned to yosys + runtime deps only (~200-400 MB).

All version-specific details (URL, SHA-256) are pinned here so downstream
modules only need:

    oss_cad_suite = use_extension("@ecos-bazel//rules:oss_cad_suite.bzl", "oss_cad_suite")
    use_repo(oss_cad_suite, "oss_cad_suite", "oss_cad_suite_pruned")
"""

load("//rules:download_and_extract.bzl", "download_and_extract")

_VERSION = "2026-01-22"
_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/{version}/oss-cad-suite-linux-x64-{tag}.tgz".format(
    version = _VERSION,
    tag = _VERSION.replace("-", ""),
)
_SHA256 = "b536961118dd7497707752d9fd45714c5f6dacd150e02387bac4f75c28a16567"

# ── Pruned repo rule ─────────────────────────────────────────────────────

def _oss_cad_suite_pruned_repo_impl(ctx):
    ctx.download_and_extract(
        url = ctx.attr.urls,
        sha256 = ctx.attr.sha256,
    )

    result = ctx.execute(["bash", str(ctx.path(ctx.attr._prune_script)), "."])
    if result.return_code != 0:
        fail("OSS CAD Suite pruning failed:\n" + result.stderr)

    ctx.template("BUILD.bazel", ctx.attr._build_file, substitutions = {})

_oss_cad_suite_pruned_repo = repository_rule(
    implementation = _oss_cad_suite_pruned_repo_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "_prune_script": attr.label(default = "//tools:prune-oss-cad-suite.sh"),
        "_build_file": attr.label(default = "//rules:oss_cad_suite.BUILD.bazel"),
    },
    doc = "Downloads OSS CAD Suite and prunes it to keep only yosys and its runtime dependencies.",
)

# ── Module extension ─────────────────────────────────────────────────────

def _oss_cad_suite_impl(_mctx):
    # Full (unpruned) suite
    download_and_extract(
        name = "oss_cad_suite",
        urls = [_URL],
        sha256 = _SHA256,
        build_file_template = "//rules:oss_cad_suite.BUILD.bazel",
    )

    # Pruned suite (yosys-only)
    _oss_cad_suite_pruned_repo(
        name = "oss_cad_suite_pruned",
        urls = [_URL],
        sha256 = _SHA256,
    )

oss_cad_suite = module_extension(
    implementation = _oss_cad_suite_impl,
)
