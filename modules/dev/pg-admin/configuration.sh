#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_pgadmin_package() {
    local ui="${1:-desktop}"

    case "$ui" in
        desktop)
            printf '%s\n' "pgadmin4-desktop"
            ;;

        web)
            printf '%s\n' "pgadmin4-web"
            ;;

        both)
            printf '%s\n' "pgadmin4"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Invalid PGADMIN_UI value: $ui. Expected desktop, web, or both."

            return 1
            ;;
    esac
}

if [[ "${PGADMIN_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    PGADMIN_PACKAGE="$(__resolve_pgadmin_package "${PGADMIN_UI:-desktop}")" || exit 1

    set_state "PGADMIN_PACKAGE" "$PGADMIN_PACKAGE"
    log_info "[$CANONICAL_ID] Selected package: $PGADMIN_PACKAGE"

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

if [[ -n "${PGADMIN_UI:-}" ]]; then
    PGADMIN_PACKAGE="$(__resolve_pgadmin_package "$PGADMIN_UI")" || exit 1

    set_state "PGADMIN_PACKAGE" "$PGADMIN_PACKAGE"
    log_info "[$CANONICAL_ID] Selected package: $PGADMIN_PACKAGE"
else
    source "${LIB_DIR}/prompt.sh"

    __ask_pgadmin_package() {
        local selected_index
        local package

        selected_index="$(
            choose_option \
                "Which pgAdmin package do you want to install?" \
                "Desktop (pgadmin4-desktop)" \
                "Web (pgadmin4-web)" \
                "Desktop and web (pgadmin4)"
        )" || return $?

        case "$selected_index" in
            0)
                package="pgadmin4-desktop"
                ;;

            1)
                package="pgadmin4-web"
                ;;

            2)
                package="pgadmin4"
                ;;

            *)
                log_error \
                    "[$CANONICAL_ID] Unexpected pgAdmin package selection index: $selected_index"

                return 1
                ;;
        esac

        set_state "PGADMIN_PACKAGE" "$package"
        log_info "[$CANONICAL_ID] Selected package: $package"

        return 0
    }

    __ask_pgadmin_package || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
