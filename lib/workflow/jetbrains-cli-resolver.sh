#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_CLI_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_CLI_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

__resolve_cli_auto_install() {
    local canonical_id="$1"
    local cli="$2"
    local auto_install="$3"
    local state_name="$4"
    local tag="$cli-auto:$canonical_id"

    case "$auto_install" in
        true)
            set_state "$state_name" "true"
            tlog_info "$tag" "Proceeding with %s installation" "$cli"
            ;;
        false)
            set_state "$state_name" "false"
            tlog_info "$tag" "User declined %s installation. Skipping" "$cli"
            ;;
        *)
            tlog_error "$tag" "Invalid %s auto install value: %s. Expected true or false." \
                "$cli" "$auto_install"

            return 1
            ;;
    esac
}

resolve_jq_auto_install() {
    local canonical_id="$1"
    local auto_install="$2"

    __resolve_cli_auto_install "$canonical_id" "jq" "$auto_install" "JETBRAINS_AUTO_INSTALL_JQ"
}

resolve_aria2_auto_install() {
    local canonical_id="$1"
    local auto_install="$2"

    __resolve_cli_auto_install "$canonical_id" "aria2c" "$auto_install" "JETBRAINS_AUTO_INSTALL_ARIA2"
}