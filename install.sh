#!/usr/bin/env bash

set -euo pipefail

#
# Global variables and required libraries
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$SCRIPT_DIR"
export INSTALL_DIR="${ROOT_DIR%/*}"
export LIB_DIR="$ROOT_DIR/lib"
export MODULES_DIR="$ROOT_DIR/modules"

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/module_installer.sh"

##
# Print the installer command-line usage to stdout.
#
# Displays the complete help text, including supported options,
# arguments, examples, and links to the project documentation.
#
# Returns:
#   0
#
installer_usage() {
    cat <<'EOF'
Usage:
  ./install.sh [OPTIONS] [MODULE...]
  ./install.sh --list [CATEGORY...]
  ./install.sh --category

Options:
  -h,  --help                 Show this help message and exit.
  -c,  --category             List available categories and exit.
  -l,  --list                 List available modules and exit.
  -ni, --non-interactive      Use defaults and auto-detection where possible.
       --unattended           Alias for --non-interactive.
  -s,  --skip-configuration   Skip supported post-install configuration.
  -fc, --force-configuration  Force supported post-install configuration.
  -f,  --force-install        Install modules even if already installed.

Arguments:
  MODULE      Module to install: <category>/<module> or <module>.
  CATEGORY    Category to filter when using -l or --list.

Examples:
  ./install.sh git
  ./install.sh cli/git eza
  ./install.sh -ni -f gui/flameshot term/kitty
  ./install.sh --list
  ./install.sh --list cli gui
  ./install.sh --category

Notes:
  * Use <category>/<module> to resolve conflicting module names.
  * --skip-configuration takes precedence over --force-configuration.
  * Non-interactive modes never prompt for sudo. Credentials must already be
    cached, or passwordless sudo must be available.

  More details:
  https://github.com/hadi-susanto/mint-provisioner/tree/main/modules
EOF
}

##
# Parses installer command-line arguments.
#
# Arguments:
#   $1 - Name of the associative array that receives parsed options.
#   $2 - Name of the indexed array that receives positional arguments.
#   $@ - Installer command-line arguments to process.
#
# Parsed options:
#   CMD                   install, help, list, or category
#   NON_INTERACTIVE       1 (true) or 0 (false)
#   SKIP_CONFIGURATION    1 (true) or 0 (false)
#   FORCE_CONFIGURATION   1 (true) or 0 (false)
#   FORCE_INSTALL         1 (true) or 0 (false)
#
# Returns:
#   0 - Arguments were parsed successfully.
#   1 - An unknown option or conflicting command was provided.
#
parse_installer_arguments() {
    local -n options_ref="$1"
    local -n args_ref="$2"
    shift 2

    options_ref=(
        [CMD]=""
        [NON_INTERACTIVE]=0
        [SKIP_CONFIGURATION]=0
        [FORCE_CONFIGURATION]=0
        [FORCE_INSTALL]=0
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

            -c|--category)
                if [[ -n "$cmd" ]]; then
                    log_error "Cannot combine '$1' with another command, current command: $cmd"

                    return 1
                fi

                cmd="category"
                ;;

            -l|--list)
                if [[ -n "$cmd" ]]; then
                    log_error "Cannot combine '$1' with another command, current command: $cmd"

                    return 1
                fi

                cmd="list"
                ;;

            -ni|--non-interactive|--unattended)
                options_ref[NON_INTERACTIVE]=1
                ;;

            -s|--skip-configuration)
                options_ref[SKIP_CONFIGURATION]=1
                ;;

            -fc|--force-configuration)
                options_ref[FORCE_CONFIGURATION]=1
                ;;

            -f|--force-install)
                options_ref[FORCE_INSTALL]=1
                ;;

            -*)
                log_error "Unknown option '$1'."
                printf '\nPlease execute install.sh --help to list all supported options.\n'

                return 1
                ;;

            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done

    #
    # Use the explicitly requested command when provided.
    #
    if [[ -n "$cmd" ]]; then
        options_ref[CMD]="$cmd"

        return 0
    fi

    #
    # Without an explicit command, positional arguments are treated as modules
    # to install. When no arguments are given, show help by default.
    #
    if (( ${#args_ref[@]} > 0 )); then
        options_ref[CMD]="install"
    else
        options_ref[CMD]="help"
    fi

    return 0
}

##
# Attempts to acquire and cache sudo privileges for the current session.
#
# Prompts the user for confirmation before running `sudo -v`.
# When successful, sudo credentials are cached to reduce repeated password
# prompts during the installation process.
#
# Returns:
#   0 - Privilege acquisition succeeded or the user declined.
#   1 - Failed to acquire sudo privileges.
#
try_acquire_sudo_privileges() {
    local response

    log_info "The script can obtain and cache sudo privileges now, so you won't need to enter your password again later."

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        log_info "Non-interactive mode: validating cached or passwordless sudo privileges..."

        if ! sudo -n -v; then
            log_error "Non-interactive mode could not acquire sudo privileges without prompting."

            return 1
        fi

        return 0
    fi

    read -r -p "Do you want to elevate privileges now? (Y/n): " response
    response="${response:-y}"

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
# Runs the installation workflow for resolved modules.
#
# Applies installer options as framework environment variables, processes
# module configuration, and executes the installation lifecycle.
#
# Arguments:
#   $1 - Name of the associative array containing installer options.
#   $@ - Resolved canonical module IDs to configure and install.
#
# Returns:
#   0 - The installation workflow completed successfully.
#   Any non-zero status returned by configuration or installation.
#
run_installation_workflow() {
    local -n options_ref="$1"
    shift

    #
    # Apply installer options.
    #
    if (( ${options_ref[NON_INTERACTIVE]:-0} == 1 )); then
        export NON_INTERACTIVE=true
        log_info "Enabling non-interactive installation. Default values or auto-detection will be used."
    fi

    if (( ${options_ref[SKIP_CONFIGURATION]:-0} == 1 )); then
        export SKIP_CONFIGURATION=true
        log_info "Disabling the configuration/post_install phase when supported by the module."
    fi

    if (( ${options_ref[FORCE_CONFIGURATION]:-0} == 1 )); then
        export FORCE_CONFIGURATION=true
        if (( ${options_ref[SKIP_CONFIGURATION]:-0} == 1 )); then
            log_warn "SKIP_CONFIGURATION is also active. It will take precedence over FORCE_CONFIGURATION."
        else
            log_info "Enabling force configuration to reset existing configuration when supported by the module."
        fi
    fi

    if (( ${options_ref[FORCE_INSTALL]:-0} == 1 )); then
        export FORCE_INSTALL=true
        log_info "Enabling force installation mode. Modules will be installed even if they are already installed."
    fi

    #
    # Process module configuration before installation.
    #
    if ! run_configuration "$@"; then
        log_error "Failed to process module configuration. Aborting installation."

        return 1
    fi

    #
    # Begin installation.
    #
    try_acquire_sudo_privileges || return $?
    run_installation "$@"
}

##
# Main entry point for the installer application.
#
# Parses command-line arguments, determines the requested command,
# and dispatches execution to the corresponding handler.
#
# Arguments:
#   $@ - Installer command-line arguments.
#
# Returns:
#   0 - The requested command completed successfully.
#   Any non-zero status returned by argument parsing or command execution.
#
main() {
    local -A options
    local -a args

    parse_installer_arguments options args "$@" || return $?

    case "${options[CMD]}" in
        help)
            installer_usage
            ;;

        category)
            list_available_categories
            ;;

        list)
            list_available_modules "${args[@]}"
            ;;

        install)
            if is_admin; then
                log_error "This script is running with administrative privileges (e.g., sudo)."
                log_error "Do not run install.sh with sudo. The script will invoke sudo when required."

                return 2
            fi

            local -a resolved_modules=()
            log_info "Resolving any <module> into <category>/<module>..."
            if ! resolve_module_selectors resolved_modules "${args[@]}"; then
                log_warn "Aborting installation due to unresolved module selector(s)."
                log_info "Please run './install.sh --list' to see all available modules."

                return 1
            fi

            run_installation_workflow options "${resolved_modules[@]}"
            ;;
        *)
            log_error "Unsupported command encountered: ${options[CMD]}"

            return 1
            ;;
    esac
}

#
# begin execution of install.sh
#
main "$@"
