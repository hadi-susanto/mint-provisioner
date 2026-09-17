#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

vscode_channel="${VSCODE_CHANNEL:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$vscode_channel" ]]; then
    if resolve_vscode_channel "$vscode_channel"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid VSCODE_CHANNEL value."
fi

source "${LIB_INSTALLER}/prompt.sh"

selected_index="$(
    choose_option \
        "Which Visual Studio Code channel do you want to install?" \
        "Stable (code, recommended)" \
        "Insiders (code-insiders)"
)" || exit $?

case "$selected_index" in
    0)
        resolve_vscode_channel "stable"
        ;;
    1)
        resolve_vscode_channel "insiders"
        ;;
    *)
        tlog_error "$tag" "Unexpected Visual Studio Code channel index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID" 
