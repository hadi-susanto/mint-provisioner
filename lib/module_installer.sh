#!/usr/bin/env bash

#
# Module lifecycle definitions
#

readonly MANDATORY_PHASES=(
    is_installed
    install
)

readonly OPTIONAL_PHASES=(
    pre_install
    install
    post_install
    cleanup
)

#
# print_header <name> <source> <description>
#
print_header() {
    local name="$1"
    local source="$2"
    local description="$3"

    echo "=================================================="
    echo " Mint Provisioner - Module Installer"
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
    echo " ✔ $name installation completed (${duration}s)"
}

#
# install_module <module>
#
# Executes a structured module installation lifecycle based on
# predefined phase scripts located under MODULES_DIR.
#
# Each module is expected to be a directory containing shell scripts
# representing lifecycle phases (e.g. is_installed.sh, install.sh).
#
# Behavior:
#
#   1. Validates that the module directory exists.
#   2. Ensures all mandatory lifecycle phase scripts exist.
#   3. Executes is_installed.sh to determine whether installation is needed.
#   4. Skips installation if already installed (unless FORCE_INSTALL=true).
#   5. Executes all optional lifecycle phases in predefined order.
#
# Parameters:
#   module   Name of the module located under MODULES_DIR.
#
# Required globals:
#   MODULES_DIR       Base directory containing all modules.
#   MANDATORY_PHASES  Array of phases that must exist in every module.
#   OPTIONAL_PHASES   Array of phases executed if present.
#   FORCE_INSTALL     (optional) If "true", forces reinstallation even
#                      if module is already installed.
#
# Phase execution rules:
#
#   Mandatory phases:
#     - Must exist as <phase>.sh inside the module directory.
#     - Missing mandatory phases will abort installation.
#
#   Optional phases:
#     - Executed only if corresponding script exists.
#
#   Special phase: is_installed
#     - Must return:
#         0 → module is already installed
#         1 → module is NOT installed
#         other → error (installation aborted)
#
# Execution flow:
#
#   MODULE_DIR/<phase>.sh
#
#   is_installed → (skip if already installed) → OPTIONAL_PHASES...
#
# Returns:
#   0   Module installed successfully or already installed.
#   1   Failure in validation or any phase execution.
#
# Dependencies:
#   - Bash 4+ (associative arrays support if used globally)
#
install_module() {
    local module="$1"
    local module_dir="$MODULES_DIR/$module"

    local phase
    local script

    #
    # Helper: build script path
    #
    script_path() {
        echo "$module_dir/$1.sh"
    }

    #
    # 1. Verify module exists
    #
    if [[ ! -d "$module_dir" ]]; then
        log_error "[install_module] Module not found: $module"

        return 1
    fi

    #
    # 2. Verify mandatory phases exist
    #
    for phase in "${MANDATORY_PHASES[@]}"; do
        script="$(script_path "$phase")"

        if [[ ! -f "$script" ]]; then
            log_error "[install_module] Missing mandatory phase '$phase' for module '$module'"

            return 1
        fi
    done

    #
    # 3. Run is_installed
    #
    script="$(script_path "is_installed")"

    log_info "[install_module] [$module] Running phase: is_installed"

    if run_script "$script"; then

        if [[ "${FORCE_INSTALL:-false}" == "true" ]]; then
            log_warn "[install_module] [$module] FORCE_INSTALL enabled, proceeding anyway"
        else
            log_warn "[install_module] [$module] Already installed"

            return 0
        fi
    else
        rc=$?

        if [[ "$rc" -ne 1 ]]; then
            log_error "[install_module] [$module] is_installed failed with error code $rc"

            return 1
        fi

        log_info "[install_module] [$module] not yet installed"
    fi

    #
    # 4. Run lifecycle phases
    #
    for phase in "${OPTIONAL_PHASES[@]}"; do

        script="$(script_path "$phase")"

        #
        # Optional phase
        #
        if [[ ! -f "$script" ]]; then
            continue
        fi

        log_info "[install_module] [$module] Running phase: $phase"

        if ! run_script "$script"; then
            log_error "[install_module] [$module] Phase failed: $phase"

            return 1
        fi
    done

    log_info "[install_module] [$module] Installation completed"

    return 0
}

#
# run_installation <module...>
#
# Executes installation lifecycle for each module and collects
# per-module metadata (status, execution time, and config values)
# into a single associative array.
#
# After execution, prints a summary table.
#
# Metadata keys:
#   <module>.NAME
#   <module>.SOURCE
#   <module>.DESCRIPTION
#   <module>.status
#   <module>.time
#
run_installation() {
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
        parse_config "$MODULES_DIR/$module" metadata

        start_time="$(date +%s)"

        print_header \
            "${metadata[$module.NAME]:-$module}" \
            "${metadata[$module.SOURCE]:-N/A}" \
            "${metadata[$module.DESCRIPTION]:-}"

        log_info "[run_installation] Perform installation module: $module..."

        #
        # Execute module installation
        #
        if install_module "$module"; then
            metadata["$module.status"]="SUCCESS"
        else
            metadata["$module.status"]="FAILED"
        fi

        end_time="$(date +%s)"
        duration=$((end_time - start_time))

        metadata["$module.time"]="$duration"

        print_footer "$module" "$duration"

        echo ""
    done

    #
    # Summary output (no function call, direct here)
    #
    echo "=================================================="
    echo "                 INSTALL SUMMARY                  "
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
        echo "              POST INSTALL  MESSAGES              "
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
