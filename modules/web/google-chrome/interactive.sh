#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

google_chrome_channel="${GOOGLE_CHROME_CHANNEL:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$google_chrome_channel" ]]; then
    if resolve_google_chrome_channel "$google_chrome_channel"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid GOOGLE_CHROME_CHANNEL value."
fi

source "${LIB_INSTALLER}/prompt.sh"

selected_index="$(
    choose_option \
        "Which Google Chrome channel do you want to install?" \
        "Stable (recommended) - Most stable" \
        "Beta - Preview features" \
        "Unstable - Development builds" \
        "Canary - Daily builds"
)" || exit $?

case "$selected_index" in
    0)
        resolve_google_chrome_channel "stable"
        ;;
    1)
        resolve_google_chrome_channel "beta"
        ;;
    2)
        resolve_google_chrome_channel "unstable"
        ;;
    3)
        resolve_google_chrome_channel "canary"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected Google Chrome channel index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
