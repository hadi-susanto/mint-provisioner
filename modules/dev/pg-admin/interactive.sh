#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

pgadmin_ui="${PGADMIN_UI:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$pgadmin_ui" ]]; then
    if resolve_pgadmin_package "$pgadmin_ui"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid PGADMIN_UI value."
fi

source "$LIB_INSTALLER/prompt.sh"

selected_index="$(
    choose_option \
        "Which pgAdmin package do you want to install?" \
        "Desktop (pgadmin4-desktop)" \
        "Web (pgadmin4-web)" \
        "Desktop and Web (pgadmin4)"
)" || exit $?

case "$selected_index" in
    0)
        resolve_pgadmin_package "desktop"
        ;;
    1)
        resolve_pgadmin_package "web"
        ;;
    2)
        resolve_pgadmin_package "both"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected pgAdmin package selection index: %s" "$selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
