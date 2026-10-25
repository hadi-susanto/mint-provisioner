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
  plan            Preview what install would do, without changing anything.
  outdated        List installed modules and their version status (alias: update).
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

__plan_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp plan [OPTIONS] MODULE...

Options:
  -f,  --force            Plan reinstallation of modules that are already
                          installed.
  -ni, --non-interactive  Plan a non-interactive run; modules without
                          non-interactive support are marked blocked.
       --unattended       Alias for --non-interactive.
  -h,  --help             Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Resolves modules and runs installed-state detection exactly like
  mp install, then prints one row per module with its action (install,
  reinstall, skip, blocked or error), SOURCE, the phases that would run,
  and notes. Detection never prompts, installs, or uses sudo.

  When modules are queued, nothing is blocked, and a terminal is attached,
  mp plan asks "Continue with installation? [y/N]". Answering yes runs
  mp install with the same modules and options; the default is no. Piped or
  redirected runs only print the plan.

  Exits 0 when the install would proceed (or was declined), 1 when a module
  is blocked or detection fails, and 2 for usage errors or unknown modules.
EOF
}

__outdated_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp outdated [OPTIONS] [MODULE...]
  mp update [OPTIONS] [MODULE...]

Options:
  -h, --help  Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias. When omitted,
          every installed module is listed.

Description:
  Lists installed modules with their installed and latest versions. Rows with
  an available update are blue; rows whose versions cannot be resolved, such
  as modules without UPDATE_MODE metadata, are yellow. Selected modules that
  are not installed are listed as not installed. Nothing is upgraded.

  UPDATE_MODE=apt reads versions from dpkg and the APT cache. When apt-mode
  modules are checked and the cache is older than 7 days, mp outdated offers
  to run sudo apt-get update first if a terminal is attached; otherwise it
  only warns.

  UPDATE_MODE=github compares the release recorded at install time with the
  latest GitHub release; modules installed before versions were recorded are
  reported as having an update available. Unauthenticated GitHub API calls
  are limited to 60 per hour; set GITHUB_TOKEN to raise the limit.

  UPDATE_MODE=external compares the recorded version with the version printed
  by the module's latest.sh, which queries the vendor.

  Exits 0 when versions were checked, 1 when detection or a version query
  fails, and 2 for usage errors or unknown modules.
EOF
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
  -h, --help   Show this help.

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
  -h, --help   Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias.

Description:
  Same as mp remove, but remove.sh runs with PURGE=true. Per module, purge
  also purges packages with their /etc configuration, removes APT repositories
  and signing keys, deletes configuration, cache and data under your home
  directory, and deletes service data directories (such as databases under
  /var/lib) and installation directories. Purge implies --force and cannot be
  undone. Use mp remove to keep them.

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
        plan)
            __plan_help
            ;;
        outdated | update)
            __outdated_help
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
