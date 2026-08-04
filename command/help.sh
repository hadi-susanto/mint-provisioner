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

__list_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp list category [OPTIONS]
  mp list modules [OPTIONS]

Options:
  -c, --category <category>  Filter by category; may be repeated.
  -s, --status <status>      Filter modules by installation status.
                             Supported: all, installed, not-installed.
                             Default: all.

Description:
  Lists supported categories or modules from the Mint Provisioner catalog.
  Module output is grouped by category and includes installation status.
  Status filters apply only to module listings.
EOF
}

__install_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp install [OPTIONS] MODULE...

Options:
  -f, --force  Process modules even when they are already installed.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Resolves and checks one or more modules before installation. Optional
  interactive setup may run before installation begins. Lifecycle installation
  phases are currently reported as mocked and are never executed.
EOF

    printf '\n%bWARNING: Do not run mp install with sudo or as root.%b\n' \
        "$COLOR_RED" "$COLOR_RESET"
    printf '%bModule installers invoke sudo themselves only when necessary.%b\n' \
        "$COLOR_YELLOW" "$COLOR_RESET"
    printf '%bRunning the entire command as root can select the wrong $HOME, create%b\n' \
        "$COLOR_YELLOW" "$COLOR_RESET"
    printf '%broot-owned files, damage your home setup, or install and configure%b\n' \
        "$COLOR_YELLOW" "$COLOR_RESET"
    printf '%bsoftware for root instead of the current user.%b\n' \
        "$COLOR_YELLOW" "$COLOR_RESET"
}

main() {
    local help_type="${1:-basic}"

    case "$help_type" in
        basic | -h | --help)
            __basic_help
            ;;
        help)
            __placeholder_help "$help_type"
            ;;
        install)
            __install_help
            ;;
        list)
            __list_help
            ;;
        *)
            log_error "Unknown help topic: %s" "$help_type"
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
