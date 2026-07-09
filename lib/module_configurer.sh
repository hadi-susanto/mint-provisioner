#!/usr/bin/env bash

#
# Now we need metadata since configuring phase will read some metadata
#
source "$LIB_DIR/metadata_parser.sh"

configurer_usage() {
    cat <<'EOF'
Usage:
  ./configurer.sh [OPTIONS] [MODULE...]

Options:
  -h, --help
      Show this help message and exit.

  -l, --list
      List all installed modules and exit.

  -a, --all
      Configure all installed modules.

Arguments:
  MODULE
      Installed module to configure.

      Modules can be specified using either format:

        <category>/<module>
        <module>

Examples:
  ./configurer.sh cli/git
  ./configurer.sh git
  ./configurer.sh gui/flameshot term/kitty dev/sdkman
  ./configurer.sh flameshot term/kitty sdkman
  ./configurer.sh --all

Notes:
  * Conflicting module name should be resolved by <category>/<module>
  * Modules can also be browsed online with more details at:

        https://github.com/hadi-susanto/mint-provisioner/tree/main/modules
EOF
}

process_configurer_options() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        configurer_usage

        return 0
        ;;

      -l|--list)
        list_installed_modules

        return 0
        ;;

      -a|--all)
        log_info "Enabling configuring all installed modules"

        return 2
        ;;
    esac
  done

  return 1
}

__print_category_header() {
    local category_id="$1"

    declare -A category_metadata=()
    local category_name="category_id"

    if parse_category_config "$category_id" category_metadata; then
        category_name="${category_metadata[$category_id.NAME]}"
    fi

    printf " -= %s =- [id: %s]\n" "$category_name" "$category_id"
    printf "%s\n" "---------------------------------------------------------------------------------------------------"
}

__print_module_row() {
    local index="$1"
    local category_id="$2"
    local module_id="$3"
    local canonical_id="$category_id/$module_id"

    if ! get_module_status "$canonical_id"; then
        return 1
    fi

    declare -A metadata=()
    if ! parse_module_config "$canonical_id" metadata; then
        return 1
    fi

    printf "%3d. %s [id: %s] [source: %s]\n" \
        "$index" "${metadata[$canonical_id.NAME]:-N/A}" "$canonical_id" "${metadata[$canonical_id.SOURCE]:-N/A}"

    return 0
}

list_installed_modules() {
    local category_dir
    local first_category=true
    local has_output_array=$(( $# == 1 ))
    if (( has_output_array )); then
        declare -n installed_modules_ref="$1"
        installed_modules_ref=()
    fi

    printf " ** INSTALLED MODULES **\n\n"

    while IFS= read -r category_dir; do
        local category_id
        category_id="${category_dir##*/}"

        if [[ "$first_category" == false ]]; then
            printf "\n"
        fi
        __print_category_header "$category_id"

        local index=1
        local module_dir
        while IFS= read -r module_dir; do
            local module_id
            module_id="${module_dir##*/}"

            if ! __print_module_row "$index" "$category_id" "$module_id"; then
                continue
            fi

            if (( has_output_array )); then
                installed_modules_ref+=("$category_id/$module_id")
            fi

            ((index++))
        done < <(list_modules_by_category "$category_id")

        first_category=false
        if (( index == 1 )); then
            printf "There is no modules under $category_id category. This is not your fault, just empty category...\n"
        fi
    done < <(list_categories)

    return 0
}

#
# __print_header <name> <source> <description>
#
__print_header() {
    local name="$1"
    local source="$2"
    local description="$3"

    echo "=================================================="
    echo " Mint Provisioner - Module (Re)Configurer"
    echo "--------------------------------------------------"
    echo " Module : $name"
    echo " Source : $source"
    echo "--------------------------------------------------"
    echo "$description"
    echo "=================================================="
}

#
# __print_footer <name> <duration_seconds>
#
__print_footer() {
    local name="$1"
    local duration="$2"

    echo "--------------------------------------------------"
    echo " ✔ $name (re)configuration completed (${duration}s)"
}

#
# configure_module <module>
#
# Determines if a module is installed and executes its post_install phase.
#
# Parameters:
#   module   Name of the module located under MODULES_DIR.
#
# Returns:
#   0   Module (re)configured successfully or not installed (skipped).
#   1   Failure in (re)configuration.
#
configure_module() {
    local module="$1"
    local module_dir="$MODULES_DIR/$module"
    local is_installed_script="$module_dir/is_installed.sh"
    local post_install_script="$module_dir/post_install.sh"

    log_info "[configure_module] [$module] Checking installation status..."

    # Use run_script directly. non-zero return (like 1) means not installed or error.
    if ! run_script "$is_installed_script" >/dev/null 2>&1; then
        log_info "[configure_module] [$module] Not installed or check failed, skipping"

        return 0
    fi

    log_info "[configure_module] [$module] Running phase: post_install"
    if [[ ! -f "$post_install_script" ]]; then
        log_info "[configure_module] [$module] No post_install.sh found, skipping (re)configuration"
        return 0
    fi

    if ! run_script "$post_install_script"; then
        log_error "[configure_module] [$module] (re)configuration failed"

        return 1
    fi

    return 0
}

#
# run_configuration <module...>
#
# Executes configuration for each module and collects
# per-module metadata (status, execution time) into an associative array.
#
# After execution, prints a summary table and post-install messages.
#
run_configuration() {
    local module
    local start_time end_time duration

    #
    # Scan for existing messages from previous runs
    #
    local existing_messages=("${STATE_DIR}"/*.messages)
    if [[ -e "${existing_messages[0]}" ]]; then
        log_warn "Found existing message files in ${STATE_DIR}, cleaning up before starting..."
        rm -f "${STATE_DIR}"/*.messages
    fi

    #
    # Single metadata store for all modules
    #
    declare -A metadata=()

    for module in "$@"; do

        #
        # Load module config into metadata
        #
        parse_module_config "$module" metadata

        start_time="$(date +%s)"

        __print_header \
            "${metadata[$module.NAME]:-$module}" \
            "${metadata[$module.SOURCE]:-N/A}" \
            "${metadata[$module.DESCRIPTION]:-}"

        log_info "[run_configuration] Perform (re)configuration module: $module..."

        #
        # Execute module (re)configuration
        #
        if configure_module "$module"; then
            metadata["$module.status"]="SUCCESS"
        else
            metadata["$module.status"]="FAILED"
        fi

        end_time="$(date +%s)"
        duration=$((end_time - start_time))

        metadata["$module.time"]="$duration"

        __print_footer "${metadata[$module.NAME]:-$module}" "$duration"

        echo ""
    done

    #
    # Summary output
    #
    echo "=================================================="
    echo "            (RE)CONFIGURATION SUMMARY             "
    echo "=================================================="
    echo ""

    printf " %-20s | %-10s | %-8s\n" "MODULE" "TIME(s)" "STATUS"
    echo "--------------------------------------------------"

    for module in "$@"; do
        printf " %-20s | %-10s | %-8s\n" \
            "${metadata[$module.NAME]:-$module}" \
            "${metadata[$module.time]:-0}" \
            "${metadata[$module.status]:-UNKNOWN}"
    done

    echo "--------------------------------------------------"
    echo "=================================================="

    #
    # Print post-install messages if any
    #
    local message_files=("${STATE_DIR}"/*.messages)
    if [[ -e "${message_files[0]}" ]]; then
        echo ""
        echo "=================================================="
        echo "         (RE)CONFIGURATION  MESSAGES              "
        echo "=================================================="

        local first=true
        for file in "${STATE_DIR}"/*.messages; do
            [[ -e "$file" ]] || continue

            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ""
            fi

            local module_id
            module_id=$(basename "$file" .messages)

            # Print module name in bold if possible
            printf "\e[1m[%s]:\e[0m\n" "$module_id"
            cat "$file"
        done
        echo "=================================================="

        # Cleanup messages after printing
        rm -f "${STATE_DIR}"/*.messages
    fi
}
