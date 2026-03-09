#!/usr/bin/env bash
# Prune an OSS CAD Suite installation to keep only yosys and its runtime deps.
# Usage: prune-oss-cad-suite.sh <oss-cad-suite-root>
#
# Reduces a full 2.3 GB install to ~200-400 MB by removing nextpnr, ghdl,
# verilator, surfer, ivl, z3, libLLVM, Python, Qt5, and other unused tools.
set -euo pipefail

_ARG="${1:?Usage: $0 <oss-cad-suite-root>}"
_ARG="$(cd "$_ARG" && pwd)"

# The archive may extract into a subdirectory (e.g. oss-cad-suite/).
# Auto-detect the actual root that contains bin/yosys.
if [ -f "$_ARG/bin/yosys" ]; then
    ROOT="$_ARG"
else
    ROOT=""
    for d in "$_ARG"/*/; do
        if [ -f "${d}bin/yosys" ]; then
            ROOT="$(cd "$d" && pwd)"
            break
        fi
    done
    if [ -z "$ROOT" ]; then
        echo "ERROR: Could not find bin/yosys under $_ARG" >&2
        exit 1
    fi
fi

# ── helpers ──────────────────────────────────────────────────────────────

# _matches_any <path> <pattern...>
#   Returns 0 if <path> basename matches any of the glob patterns.
_matches_any() {
    local base
    base="$(basename "$1")"; shift
    for pat in "$@"; do
        # shellcheck disable=SC2254
        case "$base" in
            $pat) return 0 ;;
        esac
    done
    return 1
}

# _collect_elf_closure <binary...>
#   Prints the resolved (readlink -f) paths of all shared libraries
#   transitively needed by the given ELF binaries that live under $ROOT.
_collect_elf_closure() {
    declare -A seen
    local queue=("$@")
    local qi=0

    while [ $qi -lt ${#queue[@]} ]; do
        local cur="${queue[$qi]}"
        ((qi++))

        local real
        real="$(readlink -f "$cur" 2>/dev/null)" || continue
        [ -f "$real" ] || continue
        [ -z "${seen[$real]+x}" ] || continue
        seen[$real]=1

        local deps
        deps="$(LD_LIBRARY_PATH="${ROOT}/lib:${ROOT}/libexec:${LD_LIBRARY_PATH:-}" \
                ldd "$real" 2>/dev/null || true)"

        while IFS= read -r line; do
            local lib
            lib="$(echo "$line" | sed -n 's/.*=> \(\/[^ ]*\) (.*/\1/p')"
            [ -z "$lib" ] && continue
            case "$lib" in
                "${ROOT}"/*) queue+=("$lib") ;;
            esac
        done <<< "$deps"
    done

    printf '%s\n' "${!seen[@]}"
}

# ── collect yosys ELF dependency closure ─────────────────────────────────

echo "Pruning OSS CAD Suite at: $ROOT"

yosys_bins=()
for f in "${ROOT}"/bin/yosys "${ROOT}"/bin/yosys-* \
         "${ROOT}"/bin/abc \
         "${ROOT}"/libexec/yosys "${ROOT}"/libexec/yosys-*; do
    [ -f "$f" ] || continue
    yosys_bins+=("$f")
done

echo "Tracing ELF dependencies for ${#yosys_bins[@]} binaries..."

declare -A _elf_closure
while IFS= read -r p; do
    [ -n "$p" ] && _elf_closure[$p]=1
done <<< "$(_collect_elf_closure "${yosys_bins[@]}")"

echo "ELF closure: ${#_elf_closure[@]} paths"

# _in_elf_closure <path>
#   Returns 0 if the resolved path is in the ELF closure set.
_in_elf_closure() {
    local resolved
    resolved="$(readlink -f "$1" 2>/dev/null)" || return 1
    [ -n "${_elf_closure[$resolved]+x}" ]
}

# ── 1. Prune bin/ ────────────────────────────────────────────────────────

echo "Pruning bin/..."
if [ -d "${ROOT}/bin" ]; then
    for f in "${ROOT}"/bin/*; do
        [ -e "$f" ] || continue
        _matches_any "$f" "yosys" "yosys-*" "abc" && continue
        rm -rf "$f"
    done
fi

# ── 2. Prune libexec/ ───────────────────────────────────────────────────

echo "Pruning libexec/..."
if [ -d "${ROOT}/libexec" ]; then
    for f in "${ROOT}"/libexec/*; do
        [ -e "$f" ] || continue
        _matches_any "$f" "yosys" "yosys-*" && continue
        _in_elf_closure "$f" && continue
        rm -rf "$f"
    done
fi

# ── 3. Prune lib/ ───────────────────────────────────────────────────────

# Basename globs for libs we always keep
required_lib_patterns=(
    "libc.so*" "libc-*.so" "libm.so*" "libm-*.so"
    "libz.so*" "libgcc_s.so*" "libstdc++.so*"
    "libffi.so*" "libreadline.so*"
    "libtcl8.6*" "libtk8.6*" "libtinfo.so*"
)

echo "Pruning lib/..."
if [ -d "${ROOT}/lib" ]; then
    # Remove large known-unnecessary subtrees
    for d in python3.11 python2.7 dri ghdl; do
        rm -rf "${ROOT}/lib/${d}"
    done
    rm -f "${ROOT}"/lib/libLLVM*.so* "${ROOT}"/lib/libLLVM*.a
    rm -f "${ROOT}"/lib/libQt5*.so*

    # Prune individual .so files not in required patterns or ELF closure
    for f in "${ROOT}"/lib/*.so*; do
        [ -f "$f" ] || [ -L "$f" ] || continue
        _matches_any "$f" "${required_lib_patterns[@]}" && continue
        _in_elf_closure "$f" && continue
        rm -f "$f"
    done

    # Remove lib subdirs not needed by yosys TCL scripting
    for d in "${ROOT}"/lib/*/; do
        [ -d "$d" ] || continue
        case "$(basename "$d")" in
            tcl8.6|tk8.6|pkgconfig) continue ;;
        esac
        rm -rf "$d"
    done
fi

# ── 4. Prune share/ ─────────────────────────────────────────────────────

echo "Pruning share/..."
if [ -d "${ROOT}/share" ]; then
    for d in "${ROOT}"/share/*/; do
        [ -d "$d" ] || continue
        _matches_any "$d" "yosys" && continue
        rm -rf "$d"
    done
    for f in "${ROOT}"/share/*; do
        [ -f "$f" ] && rm -f "$f"
    done

    # Prune yosys/plugins -- keep only slang.so
    if [ -d "${ROOT}/share/yosys/plugins" ]; then
        for f in "${ROOT}"/share/yosys/plugins/*; do
            [ -e "$f" ] || continue
            _matches_any "$f" "slang.so" && continue
            rm -rf "$f"
        done
    fi
fi

# ── 5. Remove unnecessary top-level directories ─────────────────────────

echo "Removing unnecessary top-level directories..."
for d in examples py3bin super_prove; do
    rm -rf "${ROOT:?}/${d}"
done

# ── summary ──────────────────────────────────────────────────────────────

echo "Pruning complete."
if command -v du &>/dev/null; then
    size="$(du -sh "$ROOT" 2>/dev/null | cut -f1)"
    echo "Pruned size: ${size}"
fi
