#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_PRE_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_PRE_UPGRADE_LOADED=1

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/jetbrains-download.sh"

main() {
    local canonical_id="$1"
    local product_release_code="$2"
    local product_name="$3"
    local tag="pre-upgrade:$canonical_id"
    local cli

    # Dependencies were installed at install time; an upgrade never prompts.
    for cli in sha256sum jq; do
        if ! command -v "$cli" >/dev/null 2>&1; then
            tlog_error "$tag" "%s is required to upgrade %s" "$cli" "$product_name"

            return 1
        fi
    done

    jetbrains_download_release "$canonical_id" "$product_release_code" "$product_name"
}
