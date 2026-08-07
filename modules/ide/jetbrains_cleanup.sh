#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_CLEANUP_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_CLEANUP_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local tag="cleanup:$canonical_id"
    local archive_file

    load_states "$canonical_id" || return $?
    archive_file="$(get_state "JETBRAINS_ARCHIVE_FILE")" || return $?
    if ! rm -f -- "$archive_file"; then
        tlog_warn "$tag" "Fail to remove %s" "$archive_file"
    fi

    delete_states "$canonical_id"
    tlog_info "$tag" "Cleanup completed successfully"
}
