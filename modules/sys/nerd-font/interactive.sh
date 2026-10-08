#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

raw_families="${NERD_FONT_FAMILIES:-${NERD_FONT_FAMILY:-}}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$raw_families" ]]; then
    if resolve_font_families "$raw_families"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" \
        "Fallback to interactive session: invalid NERD_FONT_FAMILIES/NERD_FONT_FAMILY value."
fi

source "$LIB_INSTALLER/prompt.sh"

cache_font_families || exit $?

if command -v whiptail >/dev/null 2>&1; then
    nerd_font_select_with_whiptail selected_families || exit $?
else
    printf '%bAvailable Nerd Font families:%b\n' "$COLOR_CYAN" "$COLOR_RESET" >/dev/tty
    nerd_font_print_columns
    printf '\n' >/dev/tty

    selected_families="$(
        ask_text "Enter font family name(s) to install, comma separated:"
    )" || exit $?
fi

resolve_font_families "$selected_families" || exit $?

save_states "$CANONICAL_ID"
