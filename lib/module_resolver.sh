#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if (( ${__MODULE_RESOLVER_LIB_LOADED:-0} )); then
    return 0
fi

readonly __MODULE_RESOLVER_LIB_LOADED=1

source "$LIB_DIR/module_aliases.sh"

##
# Prints sorted category directory paths, one per line.
#
list_categories() {
    find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d | sort
}

##
# Prints sorted module directory paths for a category.
#
# Parameters:
#   category_name    Category ID.
#
list_modules_by_category() {
    local category_name="$1"

    find "$MODULES_DIR/$category_name" -mindepth 1 -maxdepth 1 -type d | sort
}

##
# Prints all sorted module directory paths, one per line.
#
list_all_modules() {
    find "$MODULES_DIR" -mindepth 2 -maxdepth 2 -type d | sort
}

##
# Returns success when a selector resembles <category>/<module> form.
#
# Parameters:
#   module_id    Module selector to inspect.
#
# Returns:
#   0 when the selector resembles a canonical ID; 1 otherwise.
#
is_canonical_module_id() {
    local module_id="${1:-}"

    [[ "$module_id" == ?*/?* ]]
}

##
# Resolves one canonical, unique short, or aliased module selector.
#
# Parameters:
#   selector       Module selector.
#   result_name    Name of the destination array.
#
# Returns:
#   1 when no module matches; 2 when a short selector is ambiguous.
#
resolve_module_selector() {
    local selector="$1"
    local result_name="$2"

    declare -n result_ref="$result_name"
    result_ref=()

    if is_canonical_module_id "$selector"; then
        if [[ ! -d "$MODULES_DIR/$selector" ]]; then
            log_error "[resolver] Module not found: $selector"

            return 1
        fi

        result_ref+=("$selector")

        return 0
    fi

    local -a matches=()
    local module_dir
    while IFS= read -r module_dir; do
        local module_name
        module_name="${module_dir##*/}"

        [[ "$module_name" == "$selector" ]] || continue

        local parent_dir
        local category_name
        parent_dir="${module_dir%/*}"
        category_name="${parent_dir##*/}"
        matches+=("$category_name/$module_name")
    done < <(list_all_modules)

    if (( ${#matches[@]} == 1 )); then
        result_ref+=("${matches[0]}")
        log_info "[resolver] Module selector resolved $selector -> ${matches[0]}"

        return 0
    fi

    if (( ${#matches[@]} > 1 )); then
        log_error "[resolver] Ambiguous module selector '$selector'. Candidates: ${matches[*]}"

        return 2
    fi

    if ! is_module_alias "$selector"; then
        log_error "[resolver] Module not found: $selector"

        return 1
    fi

    local canonical_id
    if ! resolve_module_alias "$selector" canonical_id; then
        log_error "[resolver] Failed to resolve registered module alias: $selector"

        return 1
    fi

    if [[ ! -d "$MODULES_DIR/$canonical_id" ]]; then
        log_error "[resolver] Module alias '$selector' points to an unknown module: $canonical_id"

        return 1
    fi

    result_ref+=("$canonical_id")
    log_info "[resolver] Module alias resolved $selector -> $canonical_id"

    return 0
}

##
# Resolves multiple module selectors into a caller-provided array.
#
# Parameters:
#   result_name    Name of the destination array.
#   selectors      Remaining arguments are module selectors.
#
# Returns:
#   1 when any selector cannot be resolved.
#
resolve_module_selectors() {
    local result_name="$1"
    shift

    declare -n result_ref="$result_name"
    result_ref=()

    local selector
    local resolved
    local failed=false
    for selector in "$@"; do
        resolved=()

        if resolve_module_selector "$selector" resolved; then
            result_ref+=("${resolved[0]}")
        else
            failed=true
        fi
    done

    if [[ "$failed" == "true" ]]; then
        return 1
    fi

    return 0
}
