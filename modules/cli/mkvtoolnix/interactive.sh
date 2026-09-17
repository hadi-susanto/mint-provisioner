#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

mkvtoolnix_gui_enabled="${MKVTOOLNIX_GUI_ENABLED:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$mkvtoolnix_gui_enabled" ]]; then
    if resolve_mkvtoolnix_gui_enabled "$mkvtoolnix_gui_enabled"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid MKVTOOLNIX_GUI_ENABLED value."
fi

source "$LIB_INSTALLER/prompt.sh"

selected_index="$(
    choose_option \
        "Install MKVToolNix GUI alongside the CLI?" \
        "Yes, install the GUI" \
        "No, install CLI tools only"
)" || exit $?

case "$selected_index" in
    0)
        resolve_mkvtoolnix_gui_enabled "true"
        ;;
    1)
        resolve_mkvtoolnix_gui_enabled "false"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected MKVToolNix selection index: %s" "$selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
