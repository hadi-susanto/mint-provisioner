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
# Export FORCE_CONFIGURATION and SKIP_CONFIGURATION
#
export FORCE_CONFIGURATION=true
export SKIP_CONFIGURATION=false

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
# Privilege check (similar to install.sh)
#
if is_admin; then
    log_warn "This script is running with administrative privileges (e.g., sudo)."
    log_warn "It is better to run under user context, the script will use sudo whenever it's required."
else
    log_info "Usually (re)configuration will not require administrative privileges, but in some cases"
    log_info "we may need (eg: clearing font cache) hence we asked for escalated privileges"

    read -r -p "Do you want to automatically escalate privileges? (y/N): " response
    response="${response:-n}"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Acquiring sudo privileges..."
        sudo -v || {
            log_error "Failed to escalate privileges."
            exit 1
        }
    fi
fi

#
# Determine modules to configure
#
source "$LIB_DIR/metadata_parser.sh"
modules_to_configure=()

if [[ "$#" -eq 0 ]]; then
    log_info "No modules specified. Iterating over all available modules..."
    
    # Get list of all modules
    all_modules=()
    while IFS= read -r module; do
        all_modules+=("$module")
    done < <(list_available_modules)

    if [[ ${#all_modules[@]} -eq 0 ]]; then
        log_warn "No modules found in $MODULES_DIR"

        exit 0
    fi

    read -r -p "Do you want to perform configuration of any installed module? (y/N): " response
    response="${response:-n}"
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Aborting modules (re)configuration..."

        exit 0
    fi
    modules_to_configure=("${all_modules[@]}")
else
    # Check modules existence
    missing_modules=()
    for module in "$@"; do
        if [[ ! -d "$MODULES_DIR/$module" ]]; then
            missing_modules+=("$module")
        else
            modules_to_configure+=("$module")
        fi
    done

    if [[ "${#missing_modules[@]}" -gt 0 ]]; then
        log_error "The following modules do not exist:"
        for module in "${missing_modules[@]}"; do
            log_error "  - $module"
        done

        exit 1
    fi
fi

#
# Warning and confirmation prompt
#
log_warn "This script will overwrite existing configurations with Mint Provisioner defaults."
read -r -p "Are you sure you want to continue? (y/N): " confirm_response
confirm_response="${confirm_response:-n}"
if [[ ! "$confirm_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    log_info "Aborting modules (re)configuration..."

    exit 0
fi

#
# Execute modules (re)configuration logic from dedicated lib/module_configurer.sh
#
source "$LIB_DIR/module_configurer.sh"
run_configuration "${modules_to_configure[@]}"
