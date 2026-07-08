#!/usr/bin/env bash

#
# (Re)Configuration lifecycle definitions
#

#
# print_header <name> <source> <description>
#
print_header() {
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
# print_footer <name> <duration_seconds>
#
print_footer() {
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

        print_header \
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

        print_footer "${metadata[$module.NAME]:-$module}" "$duration"

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

            local module_name
            module_name=$(basename "$file" .messages)
            
            # Print module name in bold if possible
            printf "\e[1m[%s]:\e[0m\n" "$module_name"
            cat "$file"
        done
        echo "=================================================="

        # Cleanup messages after printing
        rm -f "${STATE_DIR}"/*.messages
    fi
}
