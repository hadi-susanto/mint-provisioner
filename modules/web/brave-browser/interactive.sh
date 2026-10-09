#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

brave_browser_channel="${BRAVE_BROWSER_CHANNEL:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$brave_browser_channel" ]]; then
    if resolve_brave_browser_channel "$brave_browser_channel"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid BRAVE_BROWSER_CHANNEL value."
fi

source "${LIB_INSTALLER}/prompt.sh"

selected_index="$(
    choose_option \
        "Which Brave Browser channel do you want to install?" \
        "Release (recommended) - Stable" \
        "Beta - Preview features" \
        "Nightly - Daily builds"
)" || exit $?

case "$selected_index" in
    0)
        resolve_brave_browser_channel "release"
        ;;
    1)
        resolve_brave_browser_channel "beta"
        ;;
    2)
        resolve_brave_browser_channel "nightly"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected Brave Browser channel index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
