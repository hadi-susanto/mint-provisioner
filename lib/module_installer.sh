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

readonly PHASES=(
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
    printf "%s\n" "----------------------------------------------------------------------"
}

__print_module_row() {
    local index="$1"
    local category_id="$2"
    local module_id="$3"
    local canonical_id="$category_id/$module_id"

    local status
    local status_icon
    local tag

    local -a tags=()

    get_module_status "$canonical_id"
    status="$?"
    status_icon="$(get_module_status_icon "$status")"

    declare -A metadata=()
    if ! parse_module_config "$canonical_id" metadata; then
        return 1
    fi

    if [[ -n "${metadata[$canonical_id.SOURCE]:-}" ]]; then
        tags+=("source: ${metadata[$canonical_id.SOURCE]}")
    fi

    if ! get_module_tags "$canonical_id" tags; then
        return 1
    fi

    printf "%3d. [%s] %s ${COLOR_YELLOW}[id: %s]${COLOR_RESET}" \
        "$index" \
        "$status_icon" \
        "${metadata[$canonical_id.NAME]:-N/A}" \
        "$canonical_id"

    for tag in "${tags[@]}"; do
        printf " ${COLOR_CYAN}[%s]${COLOR_RESET}" "$tag"
    done

    printf '\n'
    printf "     %s\n" "${metadata[$canonical_id.DESCRIPTION]:-N/A}"

    return 0
}

list_available_modules() {
    local category_dir
    local first_category=true

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
# __print_header <canonical_id> <name> <source> <description>
#
__print_header() {
    local canonical_id="$1"
    local name="$2"
    local source="$3"
    local description="$4"

    printf "%s\n" "----------------------------------------------------------------------"
    printf -- "-= Installing %s =- [id: %s] [source: %s]\n" \
        "$name" \
        "$canonical_id" \
        "$source"
    printf '%s\n' "$description"
    printf "%s\n" "----------------------------------------------------------------------"
}

#
# __print_footer <name> <duration_seconds>
#
__print_footer() {
    local canonical_id="$1"
    local name="$2"
    local duration="$3"

    printf "%s\n" "----------------------------------------------------------------------"
    echo " ✔ $name [id: $canonical_id] installation completed (${duration}s)"
}

configure_module() {
    local canonical_id="$1"
    local module_dir="$MODULES_DIR/$canonical_id"
    local is_installed_script="$module_dir/is_installed.sh"
    local configuration_script="$module_dir/configuration.sh"

    if [[ ! -d "$module_dir" ]]; then
        log_error "[configure_module] Module not found: $canonical_id"

        return 1
    fi

    if [[ ! -f "$configuration_script" || ! -f "$is_installed_script" ]]; then
        # No need to logging, prevent un-necessary logging
        return 0
    fi

    if run_script "$is_installed_script" "CANONICAL_ID" "$canonical_id"; then
        if [[ "${FORCE_INSTALL:-false}" != "true" ]]; then
            # Already installed, no force install flag, no need to logging just return
            return 0
        fi
    else
        rc=$?

        if [[ "$rc" -ne 1 ]]; then
            log_error "[configure_module] [$canonical_id] fail to check installation status (err: $rc)"

            return 1
        fi
    fi

    log_info "[configure_module] [$canonical_id] Running phase: configuration"
    if ! run_script "$configuration_script" "CANONICAL_ID" "$canonical_id"; then
        log_error "[configure_module] [$canonical_id] installation configuration failed"

        return 1
    fi

    return 0
}

run_configuration() {
    local canonical_id
    local index=0

    log_info "[configuration] Scanning given modules for any configuration(s)"

    for canonical_id in "$@"; do
        if configure_module "$canonical_id"; then
            ((index++))
        else
            log_error "[configuration] Failure when configuring module: $canonical_id"

            return 1
        fi
    done

    if (( index == 0 )); then
        log_info "[configuration] There is no modules require configuration"
    else
        log_info "[configuration] Successfully processing $index configuration(s)"
    fi

    return 0
}

##
# Installs a module by executing its lifecycle phase scripts.
#
# The module's is_installed.sh script is executed before the lifecycle phases:
#
# - Exit code 0:
#     The module is already installed. Installation is skipped unless
#     FORCE_INSTALL=true.
#
# - Exit code 1:
#     The module is not installed, and installation continues.
#
# - Any other exit code:
#     The installed-state check is treated as an error.
#
# Lifecycle phases are executed in the exact order defined by PHASES. A phase
# is skipped when its corresponding script does not exist. Mandatory phase
# scripts are guaranteed to exist because they were validated beforehand.
#
# Installation stops immediately when any lifecycle phase fails.
#
# Arguments:
#   $1 - Module canonical ID in the format:
#
#            <category>/<module>
#
# Returns:
#   0 - The module was installed successfully or was already installed.
#   1 - The canonical ID is empty, the module does not exist, a mandatory
#       phase is missing, the installed-state check fails, or a lifecycle
#       phase fails.
#
# Environment:
#   FORCE_INSTALL
#       When set to "true", installation continues even when the module
#       reports that it is already installed.
#
install_module() {
    local canonical_id="${1:-}"
    local module_dir="$MODULES_DIR/$canonical_id"

    local phase
    local script
    local rc

    #
    # 1. Validate the canonical ID
    #
    if [[ -z "$canonical_id" ]]; then
        log_error "[install_module] Canonical ID must not be empty."

        return 1
    fi

    #
    # 2. Verify that the module exists
    #
    if [[ ! -d "$module_dir" ]]; then
        log_error "[install_module] Module not found: $canonical_id"

        return 1
    fi

    #
    # 3. Verify that mandatory phases exist
    #
    for phase in "${MANDATORY_PHASES[@]}"; do
        script="$module_dir/$phase.sh"

        if [[ ! -f "$script" ]]; then
            log_error "[install_module] Missing mandatory phase '$phase' for module '$canonical_id'"

            return 1
        fi
    done

    #
    # 4. Run the installed-state check
    #
    script="$module_dir/is_installed.sh"

    log_info "[install_module] [$canonical_id] Running phase: is_installed"

    if run_script "$script" "CANONICAL_ID" "$canonical_id"; then
        if [[ "${FORCE_INSTALL:-false}" == "true" ]]; then
            log_warn "[install_module] [$canonical_id] FORCE_INSTALL enabled, proceed to install"
        else
            log_warn "[install_module] [$canonical_id] Requested module already installed, skipping installation"

            return 0
        fi
    else
        rc=$?

        if ((rc != 1)); then
            log_error "[install_module] [$canonical_id] Installation check failed with error code $rc"

            return 1
        fi

        log_info "[install_module] [$canonical_id] Requested module not yet installed"
    fi

    #
    # 5. Run lifecycle phases in their defined order
    #
    for phase in "${PHASES[@]}"; do
        script="$module_dir/$phase.sh"

        if [[ ! -f "$script" ]]; then
            continue
        fi

        log_info "[install_module] [$canonical_id] Running phase: $phase"

        if ! run_script "$script" "CANONICAL_ID" "$canonical_id"; then
            log_error "[install_module] [$canonical_id] Phase failed: $phase"

            return 1
        fi
    done

    log_info "[install_module] [$canonical_id] Installation completed"

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
    local canonical_id
    local start_time_ms end_time_ms duration_ms
    local total_start_time_ms total_end_time_ms total_duration_ms

    local duration
    local total_duration

    #
    # Remove messages left by previous runs.
    #
    delete_all_messages

    #
    # Single metadata store for all modules.
    #
    declare -A metadata=()

    total_start_time_ms="$(date +%s%3N)"

    for canonical_id in "$@"; do
        #
        # Load module configuration into metadata.
        #
        parse_module_config "$canonical_id" metadata

        start_time_ms="$(date +%s%3N)"

        __print_header \
            "$canonical_id" \
            "${metadata[$canonical_id.NAME]:-$canonical_id}" \
            "${metadata[$canonical_id.SOURCE]:-N/A}" \
            "${metadata[$canonical_id.DESCRIPTION]:-}"

        log_info "[installer] Performing installation for module: $canonical_id..."

        #
        # Execute module installation.
        #
        if install_module "$canonical_id"; then
            metadata["$canonical_id.status"]="SUCCESS"
        else
            metadata["$canonical_id.status"]="FAILED"
        fi

        end_time_ms="$(date +%s%3N)"
        duration_ms=$((end_time_ms - start_time_ms))

        printf -v duration '%d.%03d' \
            "$((duration_ms / 1000))" \
            "$((duration_ms % 1000))"

        metadata["$canonical_id.time"]="$duration"

        __print_footer "$canonical_id" "${metadata[$canonical_id.NAME]:-$canonical_id}" "$duration"

        printf '\n'
    done

    total_end_time_ms="$(date +%s%3N)"
    total_duration_ms=$((total_end_time_ms - total_start_time_ms))

    printf -v total_duration '%d.%03d' \
        "$((total_duration_ms / 1000))" \
        "$((total_duration_ms % 1000))"

    #
    # Print installation summary and module messages.
    #
    printf -- '-= Installation Summary =- [time: %s seconds]\n' "$total_duration"

    local index=0
    local icon
    local name
    local status
    local status_color

    for canonical_id in "$@"; do
        index=$((index + 1))

        name="${metadata[$canonical_id.NAME]:-$canonical_id}"
        status="${metadata[$canonical_id.status]:-UNKNOWN}"

        if [[ "$status" == "SUCCESS" ]]; then
            icon="✓"
            status_color="$COLOR_GREEN"
        else
            icon="✗"
            status_color="$COLOR_RED"
        fi

        printf '%d. [%s%s%s] %s [id: %s%s%s] [%s%s%s: %s second(s)]\n' \
            "$index" \
            "$status_color" "$icon" "$COLOR_RESET" \
            "$name" \
            "$COLOR_CYAN" "$canonical_id" "$COLOR_RESET" \
            "$status_color" "$status"  "$COLOR_RESET" \
            "${metadata[$canonical_id.time]:-0.000}"

        if has_messages "$canonical_id"; then
            print_messages "$canonical_id"
            printf '\n'
        fi
    done

    delete_all_messages
}
