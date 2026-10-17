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
  remove          Remove one or more modules (alias: uninstall).
  purge           Remove modules and their well-known configuration.

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
  -f,  --force            Process modules even when they are already installed.
  -ni, --non-interactive  Use supplied values, auto-detection, or defaults
                          instead of prompting during module interaction.
       --unattended       Alias for --non-interactive.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Resolves and checks one or more modules before installation. Optional
  interactive setup may run before installation begins. Installation phases
  execute in lifecycle order and stop for a module when one phase fails.

  Non-interactive modes still run module interaction scripts with a child-scoped
  NON_INTERACTIVE=true value. They never prompt while caching sudo privileges;
  cached credentials or passwordless sudo must already be available.
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

__root_warning() {
    printf '\n%bWARNING: Do not run mp remove or mp purge with sudo or as root.%b\n' \
        "$COLOR_RED" "$COLOR_RESET"
}

__remove_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp remove [OPTIONS] MODULE...
  mp uninstall [OPTIONS] MODULE...

Options:
  -f, --force  Process modules even when they are not detected as installed.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Resolves one or more modules and runs each module's remove.sh. Modules
  without remove.sh do not support removal and fail.
  Modules that are not installed are skipped unless --force is used.
EOF

    __root_warning
}

__purge_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp purge [OPTIONS] MODULE...

Options:
  -f, --force  Accepted for symmetry; purge always implies --force.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Same as mp remove, but remove.sh runs with PURGE=true so the module also
  removes its packages' configuration, repositories, well-known configuration
  locations under your home directory, and service data directories such as
  databases. Purge implies --force and cannot be undone.

  Per module, purge also: purges packages with their /etc configuration,
  removes APT repositories and signing keys, deletes configuration, cache and
  data under your home directory, deletes service data directories under
  /var/lib, and deletes installation directories. Use mp remove to keep them.

  Before anything is removed, mp purge shows a warning with your user name and
  the modules and requires you to type PURGE in an interactive terminal. It
  cannot run unattended.
EOF

    __root_warning
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
        remove | uninstall)
            __remove_help
            ;;
        purge)
            __purge_help
            ;;
        *)
            log_error "Unknown help topic: %s" "$help_type"
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
