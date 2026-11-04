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
  info            Show the details of one or more modules (alias: show).
  install         Install one or more modules.
  plan            Preview what install would do, without changing anything.
  outdated        List installed modules and their version status (alias: update).
  upgrade         Upgrade installed modules that have an update available.
  remove          Remove one or more modules (alias: uninstall).
  purge           Remove modules and their well-known configuration.
  ui              Pick a command and modules from whiptail menus.
  doctor          Check the setup and report problems, without changing anything.

Options:
  -h, --help  Show this help messages.

Description:
  Modular software installer for Ubuntu and Linux Mint.

Tip: run 'mp ui' to pick a command and modules from menus.
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
  reinstall, skip, blocked or error), SOURCE, and the phases that would run.
  Detection never prompts, installs, or uses sudo.

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
  --async, --batch [N]  Number of background workers that inspect modules
                        from one shared queue (default 6, maximum 9). Also
                        --async=N. Each worker shows its current module on
                        its own line; module logs are printed after
                        inspection.
  --porcelain           Print only modules with an available update to stdout,
                        one per line as MODULE<TAB>INSTALLED<TAB>LATEST. The
                        table and all other output go to stderr, and no
                        prompt is shown. Used by mp upgrade.
  -h, --help            Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias. When omitted,
          every installed module is listed.

Description:
  Lists installed modules as a state icon, NAME (canonical ID), CURRENT, and
  LATEST, followed by a legend. LATEST is green when an update is available;
  versions that cannot be resolved show [unknown]. Selected modules that are
  not installed are listed as not installed. Nothing is upgraded; use
  mp upgrade for that.

  UPDATE_MODE=apt reads versions from dpkg and the APT cache. When apt-mode
  modules are checked and the cache is older than 7 days, mp outdated offers
  to run sudo apt-get update first if a terminal is attached; otherwise it
  only warns.

  UPDATE_MODE=github compares the release recorded at install time with the
  latest GitHub release; modules installed before versions were recorded are
  reported as having an update available. Unauthenticated GitHub API calls
  are limited to 60 per hour; set GITHUB_TOKEN to raise the limit.

  UPDATE_MODE=external compares the recorded version with the version printed
  by the module's latest.sh, which queries the vendor. UPDATE_MODE=git
  compares the cloned commit with the latest commit of its branch, and
  UPDATE_MODE=none marks modules whose version is not tracked.

  Exits 0 when versions were checked, 1 when detection or a version query
  fails, and 2 for usage errors or unknown modules.
EOF
}

__upgrade_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp upgrade [OPTIONS] [MODULE...]

Options:
  -y, --yes   Upgrade without asking for confirmation. Sudo must already be
              cached or passwordless, and a stale APT cache is refreshed
              without asking.
  -h, --help  Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias. When omitted,
          every installed module with an available update is upgraded.

Description:
  Runs mp outdated --porcelain to find modules with an available
  update, lists them, asks for confirmation, then upgrades them one at a time
  and prints a result summary. Module install scripts are not run again.

  UPDATE_MODE=apt upgrades every installed package from UPDATE_PACKAGE with
  apt-get install --only-upgrade (apt-fast when available). UPDATE_MODE=github
  and UPDATE_MODE=external run the module's pre-upgrade.sh and upgrade.sh,
  which download the new release and replace the installed files in place,
  keeping user configuration. An application still running from its install
  directory is not replaced. UPDATE_MODE=git runs upgrade.sh, which moves the
  clone to the latest commit of its branch; a clone with local edits to
  tracked files is not touched. Modules without upgrade.sh are reported as not
  upgradable yet. When apt-mode modules are selected and the APT cache is
  older than 7 days, mp upgrade offers to run sudo apt-get update first.

  Exits 0 when every upgrade succeeded or nothing needed upgrading, 1 when an
  upgrade, detection, or version query fails, and 2 for usage errors, unknown
  modules, or a missing terminal without --yes.
EOF
}

__ui_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp ui

Options:
  -h, --help  Show this help.

Description:
  Opens a whiptail menu to choose a command (info, install, plan, outdated,
  upgrade, remove, or purge), then a checklist of modules and, when the
  command has any, a checklist of its options. Install, plan, and info offer
  every module and mark the installed ones; outdated, upgrade, remove, and
  purge offer installed modules only. Selecting no module for outdated or
  upgrade means every installed module.

  The resulting mp command line is shown for confirmation, then runs as if
  typed, so each command keeps its own prompts and confirmations. Cancel
  returns to the menu; Quit or Esc in the menu exits.

  Needs whiptail and an interactive terminal of at least 80x24, even when
  DISABLE_WHIPTAIL=true. Exits 2 when they are unavailable.
EOF
}

__info_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp info [OPTIONS] MODULE...
  mp info [OPTIONS] --installed
  mp show [OPTIONS] MODULE...

Options:
  --installed  Show every installed module instead of named modules.
  --latest     Also resolve the installed and latest versions of installed
               modules, as mp outdated does. Needs the network.
  -h, --help   Show this help.

Arguments:
  MODULE  A canonical ID, unique module ID, or registered alias. Cannot be
          combined with --installed.

Description:
  Prints one page per module: NAME, canonical ID, DESCRIPTION, aliases,
  SOURCE, CLI, UPDATE_MODE with its packages or repository, installed state,
  the registry's install path, recorded version and data path, the install
  and upgrade phases the module ships, whether mp upgrade and mp remove
  support it, its category documentation, and its GitHub releases page.
  Nothing is changed.

  Exits 0 when every module was shown, 1 when detection, the registry, or a
  version query fails, and 2 for usage errors or unknown modules.
EOF
}

__doctor_help() {
    cat <<'EOF'
Mint Provisioner
----------------

Usage:
  mp doctor [OPTIONS]

Options:
  --offline   Skip network checks (the GitHub rate-limit query).
  -h, --help  Show this help.

Description:
  Checks the Mint Provisioner setup and prints one OK, WARN, or FAIL line per
  check, with a hint for anything that is not OK. Nothing is changed: no sudo,
  no installs, no fixes.

  Checks: not running as root, the /usr/local/bin/mp and bash completion links
  point to this clone, INSTALL_DIR is writable, required tools (git, jq,
  aria2c, curl, sudo) and whiptail are present, the distribution is
  Ubuntu-based, the APT cache age, GITHUB_TOKEN and the remaining GitHub API
  calls, registry entries (module still exists, INSTALL_PATH still exists,
  VERSION recorded for github and external modules), leftover temporary
  state, and broken /usr/local/bin links or desktop entries that point into
  INSTALL_DIR.

  Exits 0 when no check fails (warnings are allowed), 1 when a check fails,
  and 2 for usage errors.
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
        upgrade)
            __upgrade_help
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
        info | show)
            __info_help
            ;;
        ui)
            __ui_help
            ;;
        doctor)
            __doctor_help
            ;;
        *)
            log_error "Unknown help topic: %s" "$help_type"
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
