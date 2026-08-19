#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATE_CLEANER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATE_CLEANER_LOADED=1

source "$LIB_INSTALLER/state.sh"

##
# auto_clean_state_files
#
# Deletes files referenced by a module's persisted FILE states and then
# removes the module's persisted states.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the persisted state file.
#
# Return:
#   0 - The state files were processed and persisted states were deleted.
#   1 - The persisted states could not be loaded or deleted.
#
auto_clean_state_files() {
    local canonical_id="$1"
    local tag="cleaner:$canonical_id"
    local key
    local file
    local status=0

    load_states "$canonical_id" || return $?

    for key in "${!__STATES[@]}"; do
        if [[ "$key" != *_FILE ]]; then
            tlog_info "$tag" "Skipping non-file state key: %s" "$key"

            continue
        fi

        file="${__STATES[$key]}"
        if rm -f -- "$file"; then
            tlog_info "$tag" "%s: %s file deleted" "$key" "$file"
        else
            tlog_warn "$tag" "Failed to delete %s (%s)" "$file" "$key"
        fi
    done

    if delete_states "$canonical_id"; then
        tlog_info "$tag" "%s states deleted successfully" "$canonical_id"
    else
        status=$?
        tlog_warn "$tag" "Fail to delete %s states" "$canonical_id"
    fi

    return "$status"
}
