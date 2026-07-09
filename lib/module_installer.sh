#!/usr/bin/env bash
#
# Now we need metadata since installing phase will read some metadata
#
source "$LIB_DIR/metadata_parser.sh"

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

installer_usage() {
    cat <<'EOF'
Usage:
  ./install.sh [OPTIONS] [MODULE...]

Options:
  -h, --help
      Show this help message and exit.

  -l, --list
      List all available modules and exit.

Arguments:
  MODULE
      Module to install.

      Modules can be specified using either format:

        <category>/<module>
        <module>

Examples:
  ./install.sh cli/git
  ./install.sh git
  ./install.sh gui/flameshot term/kitty dev/sdkman
  ./install.sh flameshot term/kitty sdkman

Notes:
  * Conflicting module name should be resolved by <category>/<module>
  * Modules can also be browsed online with more details at:

        https://github.com/hadi-susanto/mint-provisioner/tree/main/modules
EOF
}

process_installer_options() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        installer_usage

        return 0
        ;;

      -l|--list)
        list_available_modules

        return 0
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

    local status
    local status_icon

    get_module_status "$canonical_id"
    status="$?"
    status_icon="$(get_module_status_icon "$status")"

    declare -A metadata=()
    if ! parse_module_config "$canonical_id" metadata; then
        return 1
    fi

    printf "%3d. [%s] %s [id: %s] [source: %s]\n" \
        "$index" "$status_icon" "${metadata[$canonical_id.NAME]:-N/A}" "$canonical_id" "${metadata[$canonical_id.SOURCE]:-N/A}"
    printf "     %s\n" "${metadata[$canonical_id.DESCRIPTION]:-N/A}"

    return 0
}

list_available_modules() {
    local category_dir
    local first_category=true

    printf " ** AVAILABLE MODULES **\n\n"

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

            __print_module_row "$index" "$category_id" "$module_id"

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
    echo " Mint Provisioner - Module Installer"
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
        parse_module_config "$module" metadata

        start_time="$(date +%s)"

        __print_header \
            "${metadata[$module.NAME]:-$module}" \
            "${metadata[$module.SOURCE]:-N/A}" \
            "${metadata[$module.DESCRIPTION]:-}"

        log_info "[installer] Perform installation module: $module..."

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

        __print_footer "$module" "$duration"

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
