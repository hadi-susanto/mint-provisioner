#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"

__valid_catalog_id() {
    local catalog_id="$1"

    [[ "$catalog_id" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

##
# list_categories
#
# Lists supported first-level category directory IDs from MP_MODULES.
#
# Parameters:
#   categories_name - Name of the indexed array that receives category IDs.
#
list_categories() {
    local categories_name="$1"
    local -n categories_ref="$categories_name"
    local category_dir
    local category_id
    local LC_ALL=C

    categories_ref=()

    for category_dir in "$MP_MODULES"/*; do
        if [[ ! -d "$category_dir" ]] || [[ -L "$category_dir" ]]; then
            continue
        fi

        category_id="${category_dir##*/}"
        if ! __valid_catalog_id "$category_id"; then
            tlog_warn "resolver" "Skipping invalid category ID: %s" "$category_id"

            continue
        fi

        categories_ref+=("$category_id")
    done

    return 0
}

##
# list_modules
#
# Lists supported second-level module directories as canonical IDs.
#
# Parameters:
#   modules_name - Name of the indexed array that receives canonical module IDs.
#   categories   - Optional category IDs to include. All categories are used
#                  when none are provided.
#
# Returns:
#   1 when one or more requested categories are unavailable.
#
list_modules() {
    local modules_name="$1"
    shift

    local -n modules_ref="$modules_name"
    local -a available_categories=()
    local -A category_flags=()
    local -a selected_categories=()
    local category
    local invalid=0
    local category_dir
    local module_dir
    local module_id
    local canonical_id
    local LC_ALL=C

    modules_ref=()

    list_categories available_categories

    if (( $# == 0 )); then
        selected_categories=("${available_categories[@]}")
    else
        # Build a lookup table for available categories.
        for category in "${available_categories[@]}"; do
            category_flags["$category"]=0
        done

        # Validate and mark requested categories.
        for category in "$@"; do
            if [[ -v "category_flags[$category]" ]]; then
                category_flags["$category"]=1

                continue
            fi

            invalid=1
            tlog_error "resolver" "Unsupported category: %s" "$category"
        done

        if (( invalid )); then
            return 1
        fi

        # Preserve the canonical category order.
        for category in "${available_categories[@]}"; do
            if (( category_flags["$category"] )); then
                selected_categories+=("$category")
            fi
        done
    fi

    for category in "${selected_categories[@]}"; do
        category_dir="$MP_MODULES/$category"

        for module_dir in "$category_dir"/*; do
            if [[ ! -d "$module_dir" ]] || [[ -L "$module_dir" ]]; then
                continue
            fi

            module_id="${module_dir##*/}"

            if ! __valid_catalog_id "$module_id"; then
                tlog_warn "resolver" "Skipping invalid module ID: %s/%s" \
                    "$category" "$module_id"

                continue
            fi

            canonical_id="$category/$module_id"
            modules_ref+=("$canonical_id")
        done
    done

    return 0
}
