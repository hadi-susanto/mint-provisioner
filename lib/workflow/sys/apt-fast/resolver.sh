#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_APT_FAST_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_APT_FAST_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_apt_fast_package_manager <package_manager>
#
# Resolves the package manager to use with apt-fast.
#
# Parameters:
#   package_manager - Package manager (apt-get, apt, or aptitude).
#
# Return:
#   0 - Package manager resolved successfully.
#   1 - Package manager value is invalid.
#
resolve_apt_fast_package_manager() {
    local package_manager="${1:-}"
    local tag="package-manager-resolver:$CANONICAL_ID"

    case "$package_manager" in
        apt-get | apt | aptitude)
            set_state "APT_FAST_PACKAGE_MANAGER" "$package_manager"
            tlog_info "$tag" "apt-fast package manager: %s" "$package_manager"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid apt-fast package manager: %s. Expected apt-get, apt, or aptitude." \
                "$package_manager"

            return 1
            ;;
    esac
}

##
# resolve_apt_fast_max_connection <max_connection>
#
# Validates and normalizes the maximum number of apt-fast connections.
#
# Parameters:
#   max_connection - Maximum connections, from 1 to 10.
#
# Return:
#   0 - Maximum connections resolved successfully.
#   1 - Value is not an integer from 1 to 10.
#
resolve_apt_fast_max_connection() {
    local max_connection="${1:-}"
    local normalized_value=""
    local tag="max-connection-resolver:$CANONICAL_ID"

    if [[ ! "$max_connection" =~ ^[0-9]+$ ]]; then
        tlog_error "$tag" \
            "Maximum connections must be an integer from 1 to 10: %s" \
            "$max_connection"

        return 1
    fi

    normalized_value="$((10#$max_connection))"

    if (( normalized_value < 1 || normalized_value > 10 )); then
        tlog_error "$tag" \
            "Maximum connections must be between 1 and 10: %s" \
            "$max_connection"

        return 1
    fi

    set_state "APT_FAST_MAX_CONNECTION" "$normalized_value"
    tlog_info "$tag" "apt-fast maximum connections: %s" "$normalized_value"
}

##
# resolve_apt_fast_suppress_confirm_dialog <suppress_confirm_dialog>
#
# Validates and normalizes the apt-fast confirmation dialog setting.
#
# Parameters:
#   suppress_confirm_dialog - Whether to suppress the confirmation dialog (true/false).
#
# Return:
#   0 - Setting resolved successfully.
#   1 - Value is invalid.
#
resolve_apt_fast_suppress_confirm_dialog() {
    local suppress_confirm_dialog="${1:-}"
    local normalized_value=""
    local tag="suppress-confirm-resolver:$CANONICAL_ID"

    normalized_value="${suppress_confirm_dialog,,}"

    case "$normalized_value" in
        true | false)
            set_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG" "$normalized_value"
            tlog_info "$tag" "Suppress apt-fast confirmation dialog: %s" "$normalized_value"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid APT_FAST_SUPPRESS_CONFIRM_DIALOG value: %s. Expected true or false." \
                "$suppress_confirm_dialog"

            return 1
            ;;
    esac
}
