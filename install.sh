#!/usr/bin/env bash

set -euo pipefail

#
# Base directory
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# Export for plugins
#
export ROOT_DIR="$SCRIPT_DIR"
export INSTALL_DIR="$(dirname "$ROOT_DIR")"
export LIB_DIR="$ROOT_DIR/lib"
export MODULES_DIR="$ROOT_DIR/modules"

#
# Load required libraries
#
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/module_installer.sh"

#
# Backward Compatibility before lib/state.sh library
#
export STATE_DIR="$ROOT_DIR/state"
if [[ -e "$STATE_DIR" ]] && [[ ! -d "$STATE_DIR" ]]; then
    log_error "[framework] STATE_DIR exists but is not a directory: $STATE_DIR"

    exit 1
fi

if [[ ! -d "$STATE_DIR" ]]; then
    log_info "[framework] Creating STATE_DIR: $STATE_DIR"

    if ! mkdir -p "$STATE_DIR"; then
        log_error "[framework] Failed to create STATE_DIR"

        exit 2
    fi
fi

if [[ ! -w "$STATE_DIR" ]]; then
    log_error "[framework] STATE_DIR is not writable: $STATE_DIR"

    exit 3
fi

#
# No arguments -> default to show help
#
if [[ "$#" -eq 0 ]]; then
    installer_usage

    exit 0
fi
#
# Options or arguments mainly used to show help or other function outside install things
# just exit when some options was found
#
declare -a remaining_args=()
process_installer_options remaining_args "$@" || result=$?
result="${result:-0}"
case "$result" in
    0)
        exit 0
        ;;
    1)
        set -- "${remaining_args[@]}"
        ;;
    *)
        log_error "Unable to proceed, unexpected $result while processing CLI arguments"

        exit $result
        ;;
esac

#
# Resolve selectors to canonical module ids
#
declare -a resolved_modules=()
log_info "Resolving any <module> into <category>/<module>..."
if ! resolve_module_selectors resolved_modules "$@"; then
    log_warn "Aborting installation due to unresolved module selector(s)..."
    log_info "Please run './install.sh --list' to see all available module(s)"

    exit 1
fi

#
# Privilege check
#
if is_admin; then
    log_warn "This script is running with administrative privileges (e.g., sudo)."
    log_warn "It is better to run under user context, the script will use sudo whenever it's required."
else
    log_info "The script is trying to obtain and cache sudo privileges so there is no need to type password later"

    read -r -p "Do you want to automatically escalate privileges? (Y/n): " response
    response="${response:-y}"

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Acquiring sudo privileges..."

        sudo -v || {
            log_error "Failed to escalate privileges."

            exit 1
        }
    fi
fi

#
# Installation mode
#
if run_configuration "${resolved_modules[@]}"; then
    run_installation "${resolved_modules[@]}"
else
    log_error "There is failure when processing module input phase, aborting installation"
fi
