#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_NERD_FONT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_NERD_FONT_LOADED=1

source "$LIB_COMMON/common.sh"

##
# nerd_font_validate_family <font_family>
#
# Validates a Nerd Font family name for use as a directory and release name.
#
# Returns:
#   2 when the family name is empty or invalid.
#
nerd_font_validate_family() {
    local font_family="${1:-}"

    if (( $# != 1 )) ||
        [[ ! "$font_family" =~ ^[a-zA-Z0-9][a-zA-Z0-9._+-]*$ ]] ||
        [[ "$font_family" == "." || "$font_family" == ".." ]]; then
        tlog_error "nerd-font" "Invalid Nerd Font family: %s" \
            "${font_family:-<empty>}"

        return 2
    fi
}

##
# nerd_font_resolve_selection <plural_value> <singular_value> <result_name>
#
# Resolves the raw family selection, preferring a non-empty plural value.
#
# Parameters:
#   plural_value  Value from NERD_FONT_FAMILIES.
#   singular_value Value from NERD_FONT_FAMILY.
#   result_name   Variable receiving the trimmed selection.
#
# Returns:
#   1 when both selections are empty.
#   2 when the output-variable name is invalid.
#
nerd_font_resolve_selection() {
    local plural_value="${1:-}"
    local singular_value="${2:-}"
    local result_name="${3:-}"

    if (( $# != 3 )) ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        tlog_error "nerd-font" "A valid selection output variable is required"

        return 2
    fi

    local -n result_ref="$result_name"

    __trim plural_value
    __trim singular_value

    if [[ -n "$plural_value" ]]; then
        result_ref="$plural_value"

        return 0
    fi

    if [[ -n "$singular_value" ]]; then
        result_ref="$singular_value"

        return 0
    fi

    result_ref=""

    return 1
}

##
# nerd_font_parse_families <raw_families> <result_array_name>
#
# Parses, validates, trims, and deduplicates a comma-separated family list.
# The first occurrence of each family is preserved.
#
# Returns:
#   2 when the list, an entry, or the output-array name is invalid.
#
nerd_font_parse_families() {
    local raw_families="${1:-}"
    local result_name="${2:-}"

    if (( $# != 2 )) ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        tlog_error "nerd-font" "A family list and valid output array are required"

        return 2
    fi

    local -n result_ref="$result_name"
    local font_family
    local -A seen=()
    local -a parsed=()

    result_ref=()
    __trim raw_families

    if [[ -z "$raw_families" || "$raw_families" == ,* || "$raw_families" == *, ]]; then
        tlog_error "nerd-font" "Nerd Font family selection contains an empty entry"

        return 2
    fi

    IFS=',' read -r -a parsed <<<"$raw_families"

    for font_family in "${parsed[@]}"; do
        __trim font_family

        if [[ -z "$font_family" ]]; then
            tlog_error "nerd-font" "Nerd Font family selection contains an empty entry"

            return 2
        fi

        nerd_font_validate_family "$font_family" || return $?

        if [[ -v "seen[$font_family]" ]]; then
            continue
        fi

        seen["$font_family"]=1
        result_ref+=("$font_family")
    done
}

##
# nerd_font_join_families <families_array_name> <result_name>
#
# Joins an indexed family array into a comma-separated value.
#
nerd_font_join_families() {
    local families_name="$1"
    local result_name="$2"
    local -n families_ref="$families_name"
    local -n result_ref="$result_name"
    local font_family

    result_ref=""

    for font_family in "${families_ref[@]}"; do
        result_ref+="${result_ref:+,}$font_family"
    done
}

##
# nerd_font_family_installed <install_root> <font_family>
#
# Tests whether a family directory contains at least one TTF or OTF file.
#
# Returns:
#   0 when a usable font file exists.
#   1 when the family is not installed.
#   2 when validation or filesystem inspection fails.
#
nerd_font_family_installed() {
    local install_root="${1:-}"
    local font_family="${2:-}"
    local font_file

    if (( $# != 2 )) || [[ -z "$install_root" ]]; then
        tlog_error "nerd-font" "An install root and font family are required"

        return 2
    fi

    nerd_font_validate_family "$font_family" || return $?

    if [[ ! -d "$install_root/$font_family" ]]; then
        return 1
    fi

    if ! font_file="$(
        find "$install_root/$font_family" \
            -type f \
            \( -iname '*.ttf' -o -iname '*.otf' \) \
            -print \
            -quit 2>/dev/null
    )"; then
        return 2
    fi

    [[ -n "$font_file" ]]
}

##
# nerd_font_list_installed <install_root> <result_array_name>
#
# Lists valid family directories that contain usable font files.
#
# Returns:
#   2 when the arguments or filesystem inspection are invalid.
#
nerd_font_list_installed() {
    local install_root="${1:-}"
    local result_name="${2:-}"

    if (( $# != 2 )) || [[ -z "$install_root" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        tlog_error "nerd-font" "An install root and valid output array are required"

        return 2
    fi

    local -n result_ref="$result_name"
    local family_dir
    local font_family
    local status

    result_ref=()

    if [[ ! -d "$install_root" ]]; then
        return 0
    fi

    for family_dir in "$install_root"/*; do
        if [[ ! -d "$family_dir" || -L "$family_dir" ]]; then
            continue
        fi

        font_family="${family_dir##*/}"
        if ! nerd_font_validate_family "$font_family" 2>/dev/null; then
            continue
        fi

        if nerd_font_family_installed "$install_root" "$font_family"; then
            result_ref+=("$font_family")
        else
            status=$?

            if (( status > 1 )); then
                return "$status"
            fi
        fi
    done
}

##
# nerd_font_cleanup_downloads <canonical_id> <families_array_name>
#
# Removes indexed download files from loaded module state, then deletes state.
# Missing download keys and files are ignored.
#
# Returns:
#   1 when a download or the module state could not be deleted.
#
nerd_font_cleanup_downloads() {
    local canonical_id="${1:-}"
    local families_name="${2:-}"

    if (( $# != 2 )) || [[ -z "$canonical_id" ]] ||
        [[ ! "$families_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        tlog_error "nerd-font:$canonical_id" \
            "A canonical ID and valid family array are required for cleanup"

        return 1
    fi

    local -n families_ref="$families_name"
    local download_file
    local failure=0
    local index

    for (( index = 0; index < ${#families_ref[@]}; index += 1 )); do
        download_file="$(get_state "DOWNLOAD_FILE_$index" 2>/dev/null || true)"

        if [[ -z "$download_file" || ! -e "$download_file" ]]; then
            continue
        fi

        tlog_info "nerd-font:$canonical_id" "Removing downloaded file: %s" \
            "$download_file"

        if ! rm -f -- "$download_file"; then
            tlog_error "nerd-font:$canonical_id" \
                "Failed to remove downloaded file: %s" "$download_file"
            failure=1
        fi
    done

    if (( failure )); then
        return 1
    fi

    if ! delete_states "$canonical_id"; then
        tlog_error "nerd-font:$canonical_id" "Failed to delete installation state"

        return 1
    fi
}
