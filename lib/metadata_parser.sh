#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if (( ${__METADATA_PARSER_LIB_LOADED:-0} )); then
    return 0
fi

readonly __METADATA_PARSER_LIB_LOADED=1

##
# Parses module metadata into a caller-provided associative array.
#
# Parameters:
#   canonical_module_id    Module ID in <category>/<module> format.
#   result_name            Name of the destination associative array. Values
#                          are stored as <canonical-id>.<metadata-key>.
#
# Returns:
#   1 when the ID, module, metadata file, or required metadata is invalid.
#
parse_module_config() {
    local canonical_module_id="$1"
    local result_name="$2"
    local module_dir="$MODULES_DIR/$canonical_module_id"
    local config_file="${module_dir}/metadata.conf"

    if [[ "$canonical_module_id" != ?*/?* ]]; then
        log_error "[parse_module_config] Invalid module id (must be category/module): $canonical_module_id"

        return 1
    fi

    if [[ ! -d "$module_dir" ]]; then
        log_error "[parse_module_config] Module not found: $canonical_module_id"

        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "[parse_module_config] Config not found: $config_file"

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
            log_error "[parse_module_config] Missing required key: $k in $config_file"

            return 1
        fi
    done
}

##
# Parses category metadata into a caller-provided associative array.
#
# Parameters:
#   category_name    Category ID.
#   result_name      Name of the destination associative array.
#
# Returns:
#   1 when the category, metadata file, or a required key is missing.
#
parse_category_config() {
    local category_name="$1"
    local result_name="$2"
    local category_dir="$MODULES_DIR/$category_name"
    local config_file="${category_dir}/metadata.conf"

    if [[ ! -d "$category_dir" ]]; then
        log_error "[parse_category_config] Category not found: $category_name"

        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "[parse_category_config] Config not found: $config_file"

        return 1
    fi

    declare -n result="$result_name"

    local key value
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        [[ -z "$key" ]] && continue
        [[ "$key" == \#* ]] && continue

        value="${value#\"}"
        value="${value%\"}"

        result["$category_name.$key"]="$value"

    done < "$config_file"

    local required_keys=("NAME" "DESCRIPTION")
    local k
    for k in "${required_keys[@]}"; do
        if [[ -z "${result[$category_name.$k]:-}" ]]; then
            log_error "[parse_category_config] Missing required key: $k in $config_file"

            return 1
        fi
    done
}

##
# Returns the installation status reported by a module's detection script.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#
# Returns:
#   0 when installed; 1 when not installed; 2 when the module or detection
#   script is missing; otherwise the status returned by the detection script.
#
get_module_status() {
    local canonical_id="$1"
    local module_dir="$MODULES_DIR/$canonical_id"

    if [[ ! -d "$module_dir" ]]; then
        return 2
    fi

    local script="$module_dir/is_installed.sh"
    if [[ ! -f "$script" ]]; then
        return 2
    fi

    local status=0
    run_script "$script" >/dev/null 2>&1 || status=$?

    return "$status"
}

##
# Prints the colored status icon corresponding to a module status code.
#
# Parameters:
#   status    Status returned by get_module_status.
#
get_module_status_icon() {
  local status="$1"

  case "$status" in
    0)
      printf "%s" "${COLOR_GREEN}✓${COLOR_RESET}"
      ;;
    1)
      printf "%s" "${COLOR_RED}✗${COLOR_RESET}"
      ;;
    *)
      printf "%s" "${COLOR_YELLOW}⚠${COLOR_RESET}"
      ;;
  esac
}

##
# Appends lifecycle capability tags for a module to a caller-provided array.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#   tags_name       Name of the destination array.
#
get_module_tags() {
    local canonical_id="$1"
    local -n tags_ref="$2"

    local module_dir="$MODULES_DIR/$canonical_id"

    # Don't reset the tags_ref

    if [[ -f "$module_dir/configuration.sh" ]]; then
        tags_ref+=("interactive")
    fi

    if [[ -f "$module_dir/post_install.sh" ]]; then
        tags_ref+=("post-install")
    fi

    return 0
}
