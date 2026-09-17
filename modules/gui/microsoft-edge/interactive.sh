#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

microsoft_edge_channel="${MICROSOFT_EDGE_CHANNEL:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$microsoft_edge_channel" ]]; then
    if resolve_microsoft_edge_channel "$microsoft_edge_channel"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid MICROSOFT_EDGE_CHANNEL value."
fi

source "${LIB_INSTALLER}/prompt.sh"

selected_index="$(
    choose_option \
        "Which Microsoft Edge channel do you want to install?" \
        "Stable (recommended) - Most stable" \
        "Beta - Preview features" \
        "Dev - Latest features" \
        "Canary - Daily builds"
)" || exit $?

case "$selected_index" in
    0)
        resolve_microsoft_edge_channel "stable"
        ;;
    1)
        resolve_microsoft_edge_channel "beta"
        ;;
    2)
        resolve_microsoft_edge_channel "dev"
        ;;
    3)
        resolve_microsoft_edge_channel "canary"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected Microsoft Edge channel index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID" 
