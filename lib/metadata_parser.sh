#!/usr/bin/env bash

#
# parse_config <module_dir> <result_array_name>
#
# Parses a module metadata.conf file and stores the configuration
# values into the specified associative array.
#
# The resulting keys are prefixed with the module directory name
# to avoid collisions when parsing multiple modules into the same
# result array.
#
# Example:
#
#   modules/flameshot/metadata.conf
#
#       NAME="Flameshot"
#       DESCRIPTION="Screenshot tool"
#       SOURCE="github"
#
#   declare -A metadata
#   parse_config "$MODULES_DIR/flameshot" metadata
#
#   echo "${metadata[flameshot.NAME]}"
#   echo "${metadata[flameshot.DESCRIPTION]}"
#   echo "${metadata[flameshot.SOURCE]}"
#
# Parameters:
#   module_dir        - Absolute or relative module directory path
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
    local module_dir="$1"
    local result_name="$2"
    local config_file="${module_dir}/metadata.conf"

    if [[ ! -f "$config_file" ]]; then
        log_error "[parse_config] Config not found: $config_file"
        return 1
    fi

    #
    # Just declare don't reset the result array variable,
    # we pass it by reference.
    #
    declare -n result="$result_name"

    local base
    base="$(basename "$module_dir")"

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

        result["$base.$key"]="$value"

    done < "$config_file"

    #
    # Required fields (extensible).
    #
    local required_keys=("NAME" "DESCRIPTION" "SOURCE")

    for k in "${required_keys[@]}"; do
        if [[ -z "${result[$base.$k]:-}" ]]; then
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

list_available_modules() {
    # If stdout is a terminal, we print the table to stdout for the user.
    # If stdout is NOT a terminal (e.g. captured by a variable), we print the table to stderr
    # and the raw module names to stdout.
    local output_fd=1
    if [[ ! -t 1 ]]; then
        output_fd=2
    fi

    printf "\nAvailable modules:\n\n" >&$output_fd
    printf "%-3s %-16s %-12s %-12s %s\n" "No" "Name" "Source" "Status" "Description" >&$output_fd
    printf "%-3s %-16s %-12s %-12s %s\n" "---" "----------------" "------------" "------------" "----------------------------------------" >&$output_fd

    #
    # Collect modules
    #
    index=1
    while IFS= read -r module_dir; do
        declare -A metadata=()
        if ! parse_config "$module_dir" metadata; then
            continue
        fi

        module_name="$(basename "$module_dir")"

        local status
        status="$(get_module_status "$module_name")"

        printf "%3s %-16s %-12s %-12s %s\n" \
            "$index" \
            "${metadata[$module_name.NAME]:-$module_name}" \
            "${metadata[$module_name.SOURCE]:-N/A}" \
            "$status" \
            "${metadata[$module_name.DESCRIPTION]:-}" >&$output_fd
            
        # Echo the raw module name to stdout for script consumption
        echo "$module_name"
            
        ((index++))
        
    done < <(
        find "$MODULES_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            | sort
    )

    printf "\n" >&$output_fd

    return 0
}
