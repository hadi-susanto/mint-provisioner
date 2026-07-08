#!/usr/bin/env bash

#
# parse_config <canonical_module_id> <result_array_name>
#
# Parses a module metadata.conf file and stores the configuration
# values into the specified associative array.
#
# The resulting keys are prefixed with the canonical module id
# to avoid collisions when parsing multiple modules into the same
# result array.
#
# Example:
#
#   modules/desktop-utilities/flameshot/metadata.conf
#
#       NAME="Flameshot"
#       DESCRIPTION="Screenshot tool"
#       SOURCE="github"
#
#   declare -A metadata
#   parse_config "desktop-utilities/flameshot" metadata
#
#   echo "${metadata[desktop-utilities/flameshot.NAME]}"
#   echo "${metadata[desktop-utilities/flameshot.DESCRIPTION]}"
#   echo "${metadata[desktop-utilities/flameshot.SOURCE]}"
#
# Parameters:
#   canonical_module_id - Canonical module identifier: <category>/<module>
#   result_array_name - Name of associative array variable to populate
#
# Returns:
#   0 -> Configuration parsed successfully
#   1 -> Invalid configuration:
#          - metadata.conf not found
#          - required key missing
#
# Required metadata keys:
#   NAME
#   DESCRIPTION
#   SOURCE
#
parse_config() {
    local canonical_module_id="$1"
    local result_name="$2"
    local module_dir="$MODULES_DIR/$canonical_module_id"
    local config_file="${module_dir}/metadata.conf"

    if ! is_canonical_module_id "$canonical_module_id"; then
        log_error "[parse_config] Invalid module id (must be category/module): $canonical_module_id"

        return 1
    fi

    if [[ ! -d "$module_dir" ]]; then
        log_error "[parse_config] Module not found: $canonical_module_id"

        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "[parse_config] Config not found: $config_file"
        return 1
    fi

    #
    # Just declare don't reset the result array variable,
    # we pass it by reference.
    #
    declare -n result="$result_name"

    local key value

    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        #
        # Skip empty lines.
        #
        [[ -z "$key" ]] && continue

        #
        # Skip comments.
        #
        [[ "$key" == \#* ]] && continue

        #
        # Strip surrounding double quotes.
        #
        value="${value#\"}"
        value="${value%\"}"

        result["$canonical_module_id.$key"]="$value"

    done < "$config_file"

    #
    # Required fields (extensible).
    #
    local required_keys=("NAME" "DESCRIPTION" "SOURCE")

    for k in "${required_keys[@]}"; do
        if [[ -z "${result[$canonical_module_id.$k]:-}" ]]; then
            log_error "[parse_config] Missing required key: $k in $config_file"
            return 1
        fi
    done
}

#
# get_module_status <module>
#
# Determines the installation status of a module by executing the
# module's is_installed.sh script.
#
# Parameters:
#   module - Module name (directory name under $MODULES_DIR)
#
get_module_status() {
    local module="$1"
    local module_dir="$MODULES_DIR/$module"

    #
    # 1. Verify module exists.
    #
    if [[ ! -d "$module_dir" ]]; then
        echo "not exists"
        return 0
    fi

    #
    # 2. Verify required script exists and is executable.
    #
    local script="$module_dir/is_installed.sh"

    if [[ ! -f "$script" ]]; then
        echo "not file"
        return 0
    fi

    #
    # 3. Execute installation check.
    #
    if run_script "$script" >/dev/null 2>&1; then
        echo "installed"
    else
        echo "not yet"
    fi

    return 0
}

list_module_directories() {
    find "$MODULES_DIR" \
        -mindepth 2 \
        -maxdepth 2 \
        -type d \
        | sort
}

is_canonical_module_id() {
    local module_id="$1"

    [[ "$module_id" == */* ]]
}

resolve_module_selector() {
    local selector="$1"
    local result_name="$2"

    declare -n result_ref="$result_name"
    result_ref=()

    if is_canonical_module_id "$selector"; then
        if [[ -d "$MODULES_DIR/$selector" ]]; then
            result_ref+=("$selector")

            return 0
        fi

        log_error "[resolver] Module not found: $selector"

        return 1
    fi

    local matches=()
    local module_dir
    while IFS= read -r module_dir; do
        local module_name
        module_name="$(basename "$module_dir")"

        if [[ "$module_name" == "$selector" ]]; then
            local category_name
            category_name="$(basename "$(dirname "$module_dir")")"
            matches+=("$category_name/$module_name")
        fi
    done < <(list_module_directories)

    if [[ "${#matches[@]}" -eq 0 ]]; then
        log_error "[resolver] Module not found: $selector"

        return 1
    fi

    if [[ "${#matches[@]}" -gt 1 ]]; then
        log_error "[resolver] Ambiguous module selector '$selector'. Candidates: ${matches[*]}"

        return 2
    fi

    result_ref+=("${matches[0]}")

    return 0
}

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

list_available_modules() {
    # If stdout is a terminal, print the table to stdout.
    # Otherwise (e.g. command substitution), print the table to stderr
    # and the raw module IDs to stdout.
    local output_fd=1
    [[ ! -t 1 ]] && output_fd=2

    printf "Available modules:\n" >&"$output_fd"

    local current_category=""
    local index=0

    while IFS= read -r module_dir; do
        local module_name
        module_name="$(basename "$module_dir")"

        local category_name
        category_name="$(basename "$(dirname "$module_dir")")"

        local canonical_id
        canonical_id="$category_name/$module_name"

        local status
        status="$(get_module_status "$canonical_id")"

        declare -A metadata=()
        if ! parse_config "$canonical_id" metadata; then
            continue
        fi

        #
        # Print a new section whenever the category changes.
        #
        if [[ "$category_name" != "$current_category" ]]; then
            current_category="$category_name"
            index=1

            printf "\n%-3s %-32s %-12s %-12s %s\n" \
                "No" "$category_name Module" "Source" "Status" "Description" >&"$output_fd"
            printf "%-3s %-32s %-12s %-12s %s\n" \
                "---" "--------------------------------" "------------" "------------" "----------------------------------------" >&"$output_fd"
        fi

        printf "%3s %-32s %-12s %-12s %s\n" \
            "$index" \
            "$module_name" \
            "${metadata[$canonical_id.SOURCE]:-N/A}" \
            "$status" \
            "${metadata[$canonical_id.DESCRIPTION]:-}" >&"$output_fd"

        # Echo canonical module ID to stdout for script consumption.
        echo "$canonical_id"

        ((index++))

    done < <(list_module_directories)

    printf "\n" >&"$output_fd"

    return 0
}
