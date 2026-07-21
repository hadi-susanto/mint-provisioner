#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_pgadmin_package() {
    local ui="${1:-desktop}"
    local package

    case "$ui" in
        desktop)
            package="pgadmin4-desktop"
            ;;

        web)
            package="pgadmin4-web"
            ;;

        both)
            package="pgadmin4"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Invalid PGADMIN_UI value: $ui. Expected desktop, web, or both."

            return 1
            ;;
    esac

    set_state "PGADMIN_PACKAGE" "$package"
    log_info "[$CANONICAL_ID] Selected package: $package"
}

if [[ "${PGADMIN_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_pgadmin_package "${PGADMIN_UI:-desktop}" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_pgadmin_package() {
    local selected_index
    local ui

    selected_index="$(
        choose_option \
            "Which pgAdmin package do you want to install?" \
            "Desktop (pgadmin4-desktop)" \
            "Web (pgadmin4-web)" \
            "Desktop and web (pgadmin4)"
    )" || return $?

    case "$selected_index" in
        0)
            ui="desktop"
            ;;
        1)
            ui="web"
            ;;
        2)
            ui="both"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected pgAdmin package selection index: $selected_index"

            return 1
            ;;
    esac

    __resolve_pgadmin_package "$ui"
}

if [[ -n "${PGADMIN_UI:-}" ]]; then
    __resolve_pgadmin_package "$PGADMIN_UI" || exit $?
else
    __ask_pgadmin_package || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
