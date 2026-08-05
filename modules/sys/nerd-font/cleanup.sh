#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$MP_MODULES/sys/nerd-font/font.sh"

main() {
    local canonical_id="$1"
    local raw_families
    local -a font_families=()

    if ! load_states "$canonical_id"; then
        tlog_warn "cleanup:$canonical_id" "State not found, skipping cleanup"

        return 0
    fi

    if ! raw_families="$(get_state "FONT_FAMILIES")" ||
        ! nerd_font_parse_families "$raw_families" font_families; then
        tlog_error "cleanup:$canonical_id" "Invalid Nerd Font installation state"
        delete_states "$canonical_id" || true

        return 1
    fi

    nerd_font_cleanup_downloads "$canonical_id" font_families || return $?
    tlog_info "cleanup:$canonical_id" "Cleanup completed successfully"
}

main "$CANONICAL_ID"
