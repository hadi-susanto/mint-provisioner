#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local archive_dir

    if ! load_states "$canonical_id"; then
        tlog_warn "cleanup:$canonical_id" "State not found, skipping cleanup"

        return 0
    fi

    if archive_dir="$(get_state "FONT_ARCHIVES")" && [[ -d "$archive_dir" ]]; then
        tlog_info "cleanup:$canonical_id" "Removing downloaded font archives: %s" "$archive_dir"

        if ! rm -rf -- "$archive_dir"; then
            tlog_error "cleanup:$canonical_id" "Failed to remove font archive directory: %s" "$archive_dir"
            delete_states "$canonical_id" || true

            return 1
        fi
    fi

    delete_states "$canonical_id" || return $?
    tlog_info "cleanup:$canonical_id" "Cleanup completed successfully"
}

main "$CANONICAL_ID"
