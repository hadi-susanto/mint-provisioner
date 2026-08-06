#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$MP_MODULES/sys/nerd-font/font.sh"

readonly SYSTEM_FONT_DIR="/usr/local/share/fonts/nerd-font"

main() {
    local canonical_id="$1"
    local plural_selection="$2"
    local singular_selection="$3"
    local install_root="$4"
    local raw_families
    local font_family
    local status
    local -a font_families=()

    if nerd_font_resolve_selection \
        "$plural_selection" "$singular_selection" raw_families; then
        :
    else
        status=$?

        if (( status == 1 )); then
            return 1
        fi

        return "$status"
    fi

    nerd_font_parse_families "$raw_families" font_families || return $?

    if load_registry "$canonical_id"; then
        if install_root="$(get_registry "INSTALL_PATH" 2>/dev/null)"; then
            :
        else
            status=$?

            if (( status > 1 )); then
                return "$status"
            fi

            install_root="$SYSTEM_FONT_DIR"
        fi
    else
        status=$?

        if (( status > 1 )); then
            return "$status"
        fi
    fi

    for font_family in "${font_families[@]}"; do
        if nerd_font_family_installed "$install_root" "$font_family"; then
            continue
        else
            status=$?
        fi

        return "$status"
    done
}

main "$CANONICAL_ID" "${NERD_FONT_FAMILIES:-}" "${NERD_FONT_FAMILY:-}" "$SYSTEM_FONT_DIR"
