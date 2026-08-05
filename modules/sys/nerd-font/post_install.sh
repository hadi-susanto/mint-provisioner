#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$MP_MODULES/$CANONICAL_ID/font.sh"

readonly SYSTEM_FONT_DIR="/usr/local/share/fonts/nerd-font"

# Associative array keyed by font family: 0 is unmanaged and 1 is managed.
declare -A __FONT_FAMILY_FLAGS=()

__set_font_flags() {
    local flag="$1"
    shift

    local font_family

    for font_family in "$@"; do
        if (( flag )); then
            __FONT_FAMILY_FLAGS["$font_family"]=1
        elif [[ ! -v "__FONT_FAMILY_FLAGS[$font_family]" ]]; then
            __FONT_FAMILY_FLAGS["$font_family"]=0
        fi
    done
}

__detect_orphaned_fonts() {
    local registry_name="$1"
    local result_name="$2"
    local -n registry_ref="$registry_name"
    local -n result_ref="$result_name"
    local font_family

    result_ref=()

    for font_family in "${registry_ref[@]}"; do
        if [[ -v "__FONT_FAMILY_FLAGS[$font_family]" ]]; then
            __FONT_FAMILY_FLAGS["$font_family"]=1
        else
            result_ref+=("$font_family")
        fi
    done
}

__collect_managed_and_unmanaged() {
    local managed_name="$1"
    local unmanaged_name="$2"
    local -n managed_ref="$managed_name"
    local -n unmanaged_ref="$unmanaged_name"
    
    managed_ref=()
    unmanaged_ref=()
    
    for font_family in "${!__FONT_FAMILY_FLAGS[@]}"; do
        if (( __FONT_FAMILY_FLAGS["$font_family"] )); then
            managed_ref+=("$font_family")
        else
            unmanaged_ref+=("$font_family")
        fi
    done
}

__sort_font_families() {
    local families_name="$1"
    local -n families_ref="$families_name"
    local sorted_output

    if (( ${#families_ref[@]} == 0 )); then
        return 0
    fi

    if ! sorted_output="$(printf '%s\n' "${families_ref[@]}" | LC_ALL=C sort)"; then
        return 2
    fi

    mapfile -t families_ref <<<"$sorted_output"
}

__persist_warning() {
    local canonical_id="$1"
    local message="$2"

    tlog_warn "post-install:$canonical_id" "%s" "$message"

    if ! add_message "$canonical_id" warn "$message"; then
        tlog_warn "post-install:$canonical_id" \
            "Failed to persist Nerd Font reconciliation warning"
    fi
}

main() {
    local canonical_id="$1"
    local install_root="$2"
    local registry_raw=""
    local state_raw
    local managed_csv
    local orphaned_csv
    local unmanaged_csv
    local font_family
    local message
    local status
    local -a installed_fonts=()
    local -a managed_fonts=()
    local -a orphaned_fonts=()
    local -a registry_fonts=()
    local -a state_fonts=()
    local -a unmanaged_fonts=()

    __FONT_FAMILY_FLAGS=()

    if load_states "$canonical_id" 2>/dev/null; then
        state_raw="$(get_state "FONT_FAMILIES")" || return $?
        nerd_font_parse_families "$state_raw" state_fonts || return $?
    fi

    if nerd_font_list_installed "$install_root" installed_fonts; then
        :
    else
        status=$?
        tlog_error "post-install:$canonical_id" \
            "Failed to inspect the Nerd Font installation root: %s" "$install_root"

        return "$status"
    fi
    __set_font_flags 0 "${installed_fonts[@]}"

    if load_registry "$canonical_id"; then
        registry_raw="$(get_registry "NERD_FONT_FAMILIES" 2>/dev/null || true)"

        if [[ -n "$registry_raw" ]]; then
            nerd_font_parse_families "$registry_raw" registry_fonts || return $?
        fi
    else
        status=$?

        if (( status > 1 )); then
            return "$status"
        fi
    fi

    __detect_orphaned_fonts registry_fonts orphaned_fonts

    for font_family in "${state_fonts[@]}"; do
        if [[ ! -v "__FONT_FAMILY_FLAGS[$font_family]" ]]; then
            tlog_error "post-install:$canonical_id" \
                "Newly installed Nerd Font family is missing or unusable: %s" \
                "$font_family"

            return 2
        fi

        __FONT_FAMILY_FLAGS["$font_family"]=1
    done

    __collect_managed_and_unmanaged managed_fonts unmanaged_fonts

    __sort_font_families managed_fonts || return $?
    __sort_font_families orphaned_fonts || return $?
    __sort_font_families unmanaged_fonts || return $?

    nerd_font_join_families managed_fonts managed_csv
    nerd_font_join_families orphaned_fonts orphaned_csv
    nerd_font_join_families unmanaged_fonts unmanaged_csv

    if set_registry "INSTALL_PATH" "$install_root" &&
        set_registry "NERD_FONT_FAMILIES" "$managed_csv" &&
        save_registry "$canonical_id"; then
        :
    else
        status=$?
        tlog_error "post-install:$canonical_id" \
            "Failed to save the Nerd Font installation registry"

        return "$status"
    fi

    if (( ${#orphaned_fonts[@]} > 0 )); then
        message="Previously managed Nerd Font families are no longer installed and were removed from the registry: $orphaned_csv."
        __persist_warning "$canonical_id" "$message"
    fi

    if (( ${#unmanaged_fonts[@]} > 0 )); then
        message="Unmanaged Nerd Font families were found under $install_root: $unmanaged_csv.
They remain available but Mint Provisioner will not update or otherwise manage them."
        __persist_warning "$canonical_id" "$message"
    fi

    tlog_info "post-install:$canonical_id" \
        "Nerd Font registry reconciliation completed successfully"
}

main "$CANONICAL_ID" "$SYSTEM_FONT_DIR"
