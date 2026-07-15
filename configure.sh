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
# Load required libraries
#
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"
source "$LIB_DIR/module_configurer.sh"

#
# No arguments -> default to show help
#
if [[ "$#" -eq 0 ]]; then
    configurer_usage

    exit 0
fi

#
# Options or arguments mainly used to show help, list installed modules,
# or other actions outside the configuration process.
# Exit immediately when the requested action has been completed.
#
PROCESS_ALL_INSTALLED=false

process_configurer_options "$@" || result=$?
result="${result:-0}"

case "$result" in
    0)
        exit 0
        ;;
    1)
        ;;
    2)
        PROCESS_ALL_INSTALLED=true
        ;;
    *)
        log_error "Unable to proceed, unexpected $result while processing CLI arguments"
        exit $result
        ;;
esac

# Reach here means at least one module given or --all option given
declare -a modules_to_configure=()
if [[ "$PROCESS_ALL_INSTALLED" == true ]]; then
    list_installed_modules modules_to_configure
    printf "\n"

    printf 'List configurable modules: %s\n\n' \
        "$(IFS=','; printf '%s' "${modules_to_configure[*]}")"
    read -r -p "Are you sure you want to (re)configure all above modules? (y/N): " confirm_response
    confirm_response="${confirm_response:-n}"
    if [[ ! "$confirm_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Aborting modules (re)configuration..."

        exit 0
    fi
else
    if ! resolve_module_selectors modules_to_configure "$@"; then
        log_warn "Aborting modules (re)configuration due to unresolved selector(s)..."
        log_info "Please run ./configurer.sh --list to see all installed module(s)"

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
# Execute modules (re)configuration logic from dedicated lib/module_configurer.sh
#
run_configuration "${modules_to_configure[@]}"
