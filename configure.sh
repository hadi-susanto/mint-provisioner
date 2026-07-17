#!/usr/bin/env bash

set -euo pipefail

#
# Global variables and required libraries
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$SCRIPT_DIR"
export INSTALL_DIR="$(dirname "$ROOT_DIR")"
export LIB_DIR="$ROOT_DIR/lib"
export MODULES_DIR="$ROOT_DIR/modules"

# Standalone configuration always reruns supported post-install configuration.
export FORCE_CONFIGURATION=true
export SKIP_CONFIGURATION=false

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/module_configurer.sh"

##
# Print the configure command-line usage to stdout.
#
# Displays supported options, module selector syntax, examples, and notes about
# how standalone configuration maps to module post_install phases.
#
# Returns:
#   0
#
configure_usage() {
    cat <<'EOF'
Usage:
  ./configure.sh [OPTIONS] [MODULE...]

Options:
  -h, --help    Show this help message and exit.
  -l, --list    List installed modules that can be configured and exit.
  -a, --all     Configure all installed modules that provide post_install.sh.

Arguments:
  MODULE    Module to configure: <category>/<module> or <module>.

Examples:
  ./configure.sh git
  ./configure.sh cli/git
  ./configure.sh gui/flameshot term/kitty
  ./configure.sh --all

Notes:
  * Use <category>/<module> to resolve conflicting module names.
  * configure.sh configures existing installations by rerunning each selected
    module's post_install phase. It does not run complete installation phase.
  * Standalone configuration forces supported configuration to be reapplied.

More details:
  https://github.com/hadi-susanto/mint-provisioner/tree/main/modules
EOF
}

##
# Parse configure command-line arguments.
#
# Arguments:
#   $1 - Name of the associative array that receives parsed options.
#   $2 - Name of the indexed array that receives positional module selectors.
#   $@ - Configure command-line arguments to process.
#
# Parsed options:
#   CMD             configure, help, or list
#   CONFIGURE_ALL   1 when --all was requested, otherwise 0
#
# Returns:
#   0 - Arguments were parsed successfully.
#   1 - An unknown option or conflicting argument combination was provided.
#
parse_configure_arguments() {
    local -n options_ref="$1"
    local -n args_ref="$2"
    shift 2

    options_ref=(
        [CMD]=""
        [CONFIGURE_ALL]=0
    )

    args_ref=()

    local cmd=""

    while (($# > 0)); do
        case "$1" in
            -h|--help)
                if [[ -n "$cmd" ]]; then
                    log_error "Cannot combine '$1' with another command, current command: $cmd"

                    return 1
                fi

                cmd="help"
                ;;

            -l|--list)
                if [[ -n "$cmd" ]]; then
                    log_error "Cannot combine '$1' with another command, current command: $cmd"

                    return 1
                fi

                cmd="list"
                ;;

            -a|--all)
                options_ref[CONFIGURE_ALL]=1
                ;;

            -*)
                log_error "Unknown option '$1'."
                printf '\nPlease execute configure.sh --help to list all supported options.\n'

                return 1
                ;;

            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done

    # help/list are standalone commands and must not silently ignore selectors
    # or the --all option.
    if [[ -n "$cmd" ]]; then
        if (( ${options_ref[CONFIGURE_ALL]:-0} == 1 || ${#args_ref[@]} > 0 )); then
            log_error "Command '$cmd' cannot be combined with --all or module selectors."

            return 1
        fi

        options_ref[CMD]="$cmd"

        return 0
    fi

    # --all and explicit module selectors are mutually exclusive selection modes.
    if (( ${options_ref[CONFIGURE_ALL]:-0} == 1 && ${#args_ref[@]} > 0 )); then
        log_error "Cannot combine '--all' with explicit module selectors."

        return 1
    fi

    if (( ${options_ref[CONFIGURE_ALL]:-0} == 1 || ${#args_ref[@]} > 0 )); then
        options_ref[CMD]="configure"
    else
        options_ref[CMD]="help"
    fi

    return 0
}

##
# Attempts to acquire and cache sudo privileges for the current session.
#
# Prompts before running `sudo -v`. Declining is not treated as an error because
# most post-install configuration does not require administrative privileges.
#
# Returns:
#   0 - Privilege acquisition succeeded or the user declined.
#   1 - Failed to acquire sudo privileges.
#
try_acquire_sudo_privileges() {
    local response

    log_info "Most post-install configuration scripts do not require administrative privileges."
    log_info "Unless a selected module needs to modify system data, press ENTER to continue without pre-authenticating sudo."

    read -r -p "Do you want to elevate privileges now? (y/N): " response
    response="${response:-n}"

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Acquiring sudo privileges..."

        if ! sudo -v; then
            log_error "Failed to acquire sudo privileges."

            return 1
        fi
    fi

    return 0
}

##
# Run the standalone configuration workflow for resolved modules.
#
# Displays the modules that will be affected, asks for final confirmation,
# optionally pre-authenticates sudo, and executes each selected module's
# post_install phase.
#
# This workflow intentionally runs post_install rather than the pre-install
# configuration.sh phase. The global configuration flags declared at startup
# force supported configuration to be reapplied.
#
# Arguments:
#   $@ - Resolved canonical module IDs to configure.
#
# Returns:
#   0 - Configuration completed successfully or the user cancelled.
#   Any non-zero status returned while acquiring sudo privileges or running
#       module post-install configuration.
#
run_configure_workflow() {
    local confirm_response
    local module_list

    printf -v module_list '%s, ' "$@"
    module_list="${module_list%, }"

    log_warn "This script may overwrite existing configurations with Mint Provisioner defaults."
    log_warn "The following modules will be configured: $module_list"
    read -r -p "Are you sure you want to continue? (y/N): " confirm_response
    confirm_response="${confirm_response:-n}"

    if [[ ! "$confirm_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Aborting modules configuration..."

        return 0
    fi

    try_acquire_sudo_privileges || return $?
    run_post_install "$@"
}

##
# Main entry point for the standalone module configuration command.
#
# Parses command-line arguments, resolves the requested module set, and reruns
# post_install configuration for the selected installed modules.
#
# Arguments:
#   $@ - Configure command-line arguments.
#
# Returns:
#   0 - The requested command completed successfully or was cancelled by the user.
#   1 - Argument parsing, module resolution, listing, or configuration failed.
#   2 - The configure command was started with administrative privileges.
#   Any non-zero status returned by module listing or configuration.
#
main() {
    local -A options
    local -a args

    parse_configure_arguments options args "$@" || return $?

    case "${options[CMD]}" in
        help)
            configure_usage
            ;;

        list)
            list_installed_modules
            ;;

        configure)
            if is_admin; then
                log_error "This script is running with administrative privileges (e.g., sudo)."
                log_error "Do not run configure.sh with sudo. The script will invoke sudo when required."

                return 2
            fi

            local -a resolved_modules=()

            if (( ${options[CONFIGURE_ALL]:-0} == 1 )); then
                log_info "Collecting installed modules with a post_install phase..."
                list_installed_modules resolved_modules || return $?
            else
                log_info "Resolving any <module> into <category>/<module>..."
                if ! resolve_module_selectors resolved_modules "${args[@]}"; then
                    log_warn "Aborting module configuration due to unresolved module selector(s)."
                    log_info "Please run './configure.sh --list' to see installed configurable modules."

                    return 1
                fi
            fi

            if (( ${#resolved_modules[@]} == 0 )); then
                log_info "No installed modules with a post_install phase were found."

                return 0
            fi

            run_configure_workflow "${resolved_modules[@]}"
            ;;

        *)
            log_error "Unsupported command encountered: ${options[CMD]}"

            return 1
            ;;
    esac
}

#
# Begin execution of configure.sh
#
main "$@"
