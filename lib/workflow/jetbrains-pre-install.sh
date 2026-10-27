#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_PRE_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_PRE_INSTALL_LOADED=1

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/jetbrains-download.sh"

__auto_install_dependency() {
    local canonical_id="$1"
    local cli="$2"
    local mandatory="$3"
    local state_name="$4"
    local package_name="${5:-$cli}"
    local tag="auto-$cli:$canonical_id"
    local auto_install

    if command -v "$cli" >/dev/null 2>&1; then
        tlog_info "$tag" "%s already available" "$cli"

        return 0
    fi

    tlog_info "$tag" "%s not found; checking whether installation is allowed" "$cli"
    auto_install="$(get_state "$state_name")" || return $?
    if [[ "$auto_install" != "true" ]]; then
        if (( $mandatory )); then
            tlog_error "$tag" \
                "%s is required, but automatic installation was not allowed" "$cli"

            return 1
        else
            tlog_warn "$tag" "%s not found; installation was not allowed, using fallback"

            return 0
        fi
    fi

    source "$LIB_INSTALLER/apt.sh"
    tlog_info "$tag" "Installing dependency: %s (package: %s)" "$cli" "$package_name"
    apt_install "$canonical_id" "$package_name"
}

main() {
    local canonical_id="$1"
    local product_release_code="$2"
    local product_name="$3"
    local raw_install_path="$4"
    local env_name="$5"
    local tag="pre-install:$canonical_id"

    load_states "$canonical_id" || return $?
    tlog_info "$tag" "Validating %s installation requirements" "$product_name"
    if ! command -v sha256sum >/dev/null 2>&1; then
        tlog_error "$tag" "sha256sum is required for %s installation" "$product_name"

        return 1
    fi

    __auto_install_dependency \
        "$canonical_id" "jq" 1 "JETBRAINS_AUTO_INSTALL_JQ"  || return $?
    __auto_install_dependency \
        "$canonical_id" "aria2c" 0 "JETBRAINS_AUTO_INSTALL_ARIA2" "aria2" || return $?
    valid_install_target "$canonical_id" "$raw_install_path" "$env_name" >/dev/null || return $?

    jetbrains_download_release "$canonical_id" "$product_release_code" "$product_name"
}
