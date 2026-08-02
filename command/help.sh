#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

__basic_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp [command] [args...]

Commands:
  help [command]  Show basic help or details for a command.
  list            List available modules or categories.
  install         Install one or more modules.

Options:
  -h, --help  Show this help messages.

Description:
  Modular software installer for Ubuntu and Linux Mint.
EOF
}

__placeholder_help() {
    local command="$1"

    cat <<EOF
Mint Provisioner
----------------

Detailed help for the $command command is not available yet.
EOF
}

main() {
    local help_type="${1:-basic}"

    case "$help_type" in
        basic | -h | --help)
            __basic_help
            ;;
        list | install)
            __placeholder_help "$help_type"
            ;;
        *)
            log_error "Unknown help topic: %s" "$help_type"
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
