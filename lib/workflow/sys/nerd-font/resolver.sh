#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_NERD_FONT_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_NERD_FONT_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

# Cache of Nerd Font family names published in the latest GitHub release,
# keyed by family name so membership checks are a plain `-v` test.
declare -A __CACHED_FONT_FAMILIES=()

##
# nerd_font_parse_families <raw_families> <result_array_name>
#
# Splits, trims, and deduplicates a comma-separated family list. The first
# occurrence of each family is preserved. Family existence is validated
# separately, against the available font list.
#
# Parameters:
#   raw_families - Comma-separated font family selection.
#   result_array_name - Name of the indexed array that receives the parsed families.
#
# Return:
#   2 - The list, an entry, or the output-array name is invalid.
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

        if [[ -v "seen[$font_family]" ]]; then
            continue
        fi

        seen["$font_family"]=1
        result_ref+=("$font_family")
    done
}

##
# cache_font_families
#
# Fetches every Nerd Font family published as a `.tar.xz` asset in the latest
# ryanoasis/nerd-fonts GitHub release into __CACHED_FONT_FAMILIES. A call that
# finds the cache already populated is a no-op.
#
# Return:
#   2 - The GitHub release API request failed.
#   3 - The GitHub release response could not be parsed.
#
cache_font_families() {
    local tag="nerd-font:$CANONICAL_ID"
    local api_url="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    local body
    local urls
    local url
    local font_family
    local -a curl_args=(-fsSL)

    if (( ${#__CACHED_FONT_FAMILIES[@]} > 0 )); then
        return 0
    fi

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    tlog_info "$tag" "Fetching the available Nerd Font families: %s" "$api_url"

    if ! body="$(curl "${curl_args[@]}" "$api_url")"; then
        tlog_error "$tag" "Failed to fetch the GitHub release API"

        return 2
    fi

    if command -v jq >/dev/null 2>&1; then
        if ! urls="$(printf '%s\n' "$body" | jq -r '.assets[].browser_download_url')"; then
            tlog_error "$tag" "Failed to parse the GitHub release response"

            return 3
        fi
    else
        urls="$(printf '%s\n' "$body" | grep -o 'https://[^\"]*' || true)"
    fi

    while IFS= read -r url; do
        if [[ "$url" != *.tar.xz ]]; then
            continue
        fi

        font_family="${url##*/}"
        font_family="${font_family%.tar.xz}"
        __CACHED_FONT_FAMILIES["$font_family"]=1
    done <<<"$urls"
}

##
# nerd_font_print_columns
#
# Prints every cached Nerd Font family name to the terminal in multiple
# columns using `column` when available, falling back to one name per line.
# Requires cache_font_families to have populated __CACHED_FONT_FAMILIES.
#
nerd_font_print_columns() {
    if command -v column >/dev/null 2>&1; then
        printf '%s\n' "${!__CACHED_FONT_FAMILIES[@]}" | sort | column >/dev/tty
    else
        printf '%s\n' "${!__CACHED_FONT_FAMILIES[@]}" | sort >/dev/tty
    fi
}

##
# nerd_font_select_with_whiptail <result_name>
#
# Presents every cached Nerd Font family in a whiptail checklist and returns
# the families the user checked. Requires cache_font_families to have
# populated __CACHED_FONT_FAMILIES.
#
# Parameters:
#   result_name - Variable receiving the comma-separated selection.
#
# Return:
#   1 - The checklist was cancelled, failed, or nothing was selected.
#
nerd_font_select_with_whiptail() {
    local result_name="${1:-}"
    local -n result_ref="$result_name"
    local tag="nerd-font:$CANONICAL_ID"
    local font_family
    local selected_raw
    local newt_colors="${NEWT_COLORS:-root=,blue}"
    local -a sorted_families=()
    local -a checklist_args=()
    local -a checked_families=()

    mapfile -t sorted_families < <(printf '%s\n' "${!__CACHED_FONT_FAMILIES[@]}" | sort)

    for font_family in "${sorted_families[@]}"; do
        checklist_args+=("$font_family" "" OFF)
    done

    if ! selected_raw="$(
        NEWT_COLORS="$newt_colors" \
            whiptail --title "Nerd Fonts" --separate-output --checklist \
            "Select font families to install (space to toggle, enter to confirm)" \
            24 70 15 \
            "${checklist_args[@]}" \
            3>&1 1>&2 2>&3
    )"; then
        tlog_error "$tag" "Font family selection was cancelled"

        return 1
    fi

    mapfile -t checked_families <<<"$selected_raw"

    if (( ${#checked_families[@]} == 0 )) || [[ -z "${checked_families[0]}" ]]; then
        tlog_error "$tag" "At least one font family must be selected"

        return 1
    fi

    result_ref=""

    for font_family in "${checked_families[@]}"; do
        result_ref+="${result_ref:+,}$font_family"
    done
}

##
# resolve_font_families <raw_families>
#
# Validates a comma-separated Nerd Font family selection against the cached
# fonts published in the latest GitHub release, then stores the normalized
# selection in the FONT_FAMILIES module state.
#
# Parameters:
#   raw_families - Comma-separated font family selection.
#
# Return:
#   2 - The selection is empty, malformed, names an unknown family, or
#       caching the available Nerd Font families failed.
#
resolve_font_families() {
    local raw_families="${1:-}"
    local tag="nerd-font:$CANONICAL_ID"
    local normalized_families=""
    local font_family
    local -a font_families=()

    nerd_font_parse_families "$raw_families" font_families || return $?
    cache_font_families || return $?

    for font_family in "${font_families[@]}"; do
        if [[ ! -v "__CACHED_FONT_FAMILIES[$font_family]" ]]; then
            tlog_error "$tag" "Unknown Nerd Font family: %s" "$font_family"

            return 2
        fi

        normalized_families+="${normalized_families:+,}$font_family"
    done

    set_state "FONT_FAMILIES" "$normalized_families" || return $?
    tlog_info "$tag" "Selected Nerd Font families: %s" "$normalized_families"
}
