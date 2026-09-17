#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

brave_origin_channel="${BRAVE_ORIGIN_CHANNEL:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$brave_origin_channel" ]]; then
    if resolve_brave_origin_channel "$brave_origin_channel"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid BRAVE_ORIGIN_CHANNEL value."
fi

source "${LIB_INSTALLER}/prompt.sh"

selected_index="$(
    choose_option \
        "Which Brave Origin channel do you want to install?" \
        "Release (recommended) - Stable" \
        "Beta - Preview features" \
        "Nightly - Daily builds"
)" || exit $?

case "$selected_index" in
    0)
        resolve_brave_origin_channel "release"
        ;;
    1)
        resolve_brave_origin_channel "beta"
        ;;
    2)
        resolve_brave_origin_channel "nightly"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected Brave Origin channel index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
