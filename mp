#!/usr/bin/env bash
set -euo pipefail

__script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
__script_dir="$(cd -- "$(dirname -- "$__script_path")" && pwd -P)"

export MP_ROOT="$__script_dir"
export MP_COMMAND="$MP_ROOT/command"
export MP_MODULES="$MP_ROOT/modules"
export LIB_COMMON="$MP_ROOT/lib/common"
export LIB_INSTALLER="$MP_ROOT/lib/installer"
export LIB_MISC="$MP_ROOT/lib/misc"

main() {
    exec bash "$MP_COMMAND/main.sh" "$@"
}

main "$@"
