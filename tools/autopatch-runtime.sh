#!/usr/bin/env bash
# Bundle runtime dependencies using auto-patchelf
set -euo pipefail

# Accept destination directory as parameter
dest_bin_dir="" dest_lib_dir="" ecc_py_dir="" runtime_lib_path=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dest-bin-dir) dest_bin_dir="$2"; shift 2 ;;
        --dest-lib-dir) dest_lib_dir="$2"; shift 2 ;;
        --ecc-py) ecc_py_dir="$2"; shift 2 ;;
        --runtime-lib-path) runtime_lib_path="$2"; shift 2 ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$dest_bin_dir" || -z "$dest_lib_dir" ]]; then
    echo "ERROR: --dest-bin-dir and --dest-lib-dir are required" >&2
    exit 1
fi

mkdir -p "$dest_lib_dir"

# Copy .so files
find -L "${ecc_py_dir:-.}" -maxdepth 1 -name '*.so' -exec cp -f {} "$dest_bin_dir/" \; 2>/dev/null || true
[[ -n "$runtime_lib_path" ]] && find -L "$runtime_lib_path" -maxdepth 1 -name '*.so' -exec cp -f {} "$dest_lib_dir/" \; 2>/dev/null || true
chmod -R u+w "$dest_bin_dir" "$dest_lib_dir" 2>/dev/null || true

# Run auto-patchelf
search_paths=("$dest_lib_dir" /lib /lib64 /usr/lib /usr/lib64 /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu)
"${AUTO_PATCHELF_BIN:-auto-patchelf}" --no-recurse --ignore-missing --paths "$dest_bin_dir" "$dest_lib_dir" --libs "${search_paths[@]}"

# Set RUNPATH
find "$dest_bin_dir" -maxdepth 1 -name '*.so' -exec patchelf --set-rpath '$ORIGIN:$ORIGIN/lib' {} \; 2>/dev/null || true
find "$dest_lib_dir" -maxdepth 1 -name '*.so' -exec patchelf --set-rpath '$ORIGIN' {} \; 2>/dev/null || true

echo "[bundle] done"
