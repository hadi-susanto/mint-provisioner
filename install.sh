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
export STATE_DIR="$ROOT_DIR/state"

#
# Load common helpers
#
source "${LIB_DIR}/common.sh"

#
# Ensure STATE_DIR is exists and indeed a directory
#
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
# Now metadata parser will be used to parse metadata before installing to print header
#
source "$LIB_DIR/metadata_parser.sh"

#
# No arguments -> list modules
#
if [[ "$#" -eq 0 ]]; then
    list_available_modules > /dev/null

    echo "Usage:"
    echo "  ./install.sh <module> [module...]"
    echo ""
    echo "Example:"
    echo "  ./install.sh development/git terminal/eza"

    exit 0
fi

#
# Resolve selectors to canonical module ids
#
resolved_modules=()

if ! resolve_module_selectors resolved_modules "$@"; then
    log_warn "Aborting installation due to unresolved module selector(s)..."
    log_info "Please run ./install.sh to see all available module(s)"

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
source "$LIB_DIR/module_installer.sh"
run_installation "${resolved_modules[@]}"
