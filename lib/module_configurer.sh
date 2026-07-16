#!/usr/bin/env bash

#
# Now we need metadata since configuring phase will read some metadata
#
source "$LIB_DIR/metadata_parser.sh"

__print_module_row() {
    local index="$1"
    local category_id="$2"
    local module_id="$3"
    local have_post_install="$4"
    local canonical_id="$category_id/$module_id"
    local post_install_icon

    if ! get_module_status "$canonical_id"; then
        # Not installed or other error
        return 1
    fi

    declare -A metadata=()
    if ! parse_module_config "$canonical_id" metadata; then
        # Shouldn't happen, but kept for safety
        return 1
    fi

    if (( have_post_install )); then
        post_install_icon="${COLOR_GREEN}✓${COLOR_RESET}"
    else
        post_install_icon="${COLOR_RED}✗${COLOR_RESET}"
    fi

    local -a tags=()
    if [[ -n "${metadata[$canonical_id.SOURCE]:-}" ]]; then
        tags+=("source: ${metadata[$canonical_id.SOURCE]}")
    fi

    if ! get_module_tags "$canonical_id" tags; then
        return 1
    fi

    printf "%3d. [%s] %s ${COLOR_YELLOW}[id: %s]${COLOR_RESET}" \
        "$index" \
        "$post_install_icon" \
        "${metadata[$canonical_id.NAME]:-N/A}" \
        "$canonical_id"

    for tag in "${tags[@]}"; do
        printf " ${COLOR_CYAN}[%s]${COLOR_RESET}" "$tag"
    done

    printf '\n'

    return 0
}

list_installed_modules() {
    local category_dir
    local has_output_array=$(( $# == 1 ))
    if (( has_output_array )); then
        declare -n installed_modules_ref="$1"
        installed_modules_ref=()
    fi

    printf "Installed modules\n"
    printf "%s\n" "======================================================================"

    local index=1
    local category_id
    local module_dir
    local have_post_install
    while IFS= read -r category_dir; do
        category_id="${category_dir##*/}"

        while IFS= read -r module_dir; do
            local module_id
            module_id="${module_dir##*/}"

            if [[ -f "$MODULES_DIR/$category_id/$module_id/post_install.sh" ]]; then
                have_post_install=1
            else
                have_post_install=0
            fi

            if ! __print_module_row "$index" "$category_id" "$module_id" "$have_post_install"; then
                continue
            fi

            if (( has_output_array && have_post_install )); then
                installed_modules_ref+=("$category_id/$module_id")
            fi

            ((++index))
        done < <(list_modules_by_category "$category_id")
    done < <(list_categories)

    printf '\nLegends:\n'
    printf "  [${COLOR_GREEN}✓${COLOR_RESET}] Module has a post-install phase and can be configured.\n"
    printf "  [${COLOR_RED}✗${COLOR_RESET}] Module does not have a post-install phase and cannot be configured.\n"

    return 0
}

#
# __print_header <name> <source> <description>
#
__print_header() {
    local canonical_id="$1"
    local name="$2"
    local source="$3"
    local description="$4"

    printf "%s\n" "----------------------------------------------------------------------"
    printf -- "-= Configuring %s =- ${COLOR_YELLOW}[id: %s]${COLOR_RESET} ${COLOR_CYAN}[source: %s] [post-install]${COLOR_RESET}\n" \
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
    printf " ${COLOR_GREEN}✔${COLOR_RESET} $name ${COLOR_YELLOW}[id: $canonical_id]${COLOR_RESET} configuration completed (${duration}s)\n"
}

#
# post_install_module <module>
#
# Determines if a module is installed and executes its post_install phase.
#
# Parameters:
#   module   Name of the module located under MODULES_DIR.
#
# Returns:
#   0   Module configured successfully or not installed (skipped).
#   1   Failure in configuration.
#
post_install_module() {
    local module="$1"
    local module_dir="$MODULES_DIR/$module"
    local is_installed_script="$module_dir/is_installed.sh"
    local post_install_script="$module_dir/post_install.sh"

    log_info "[configuring] [$module] Checking installation status..."

    # Use run_script directly. non-zero return (like 1) means not installed or error.
    if ! run_script "$is_installed_script" >/dev/null 2>&1; then
        log_info "[configuring] [$module] Not installed or check failed, skipping"

        return 0
    fi

    if [[ ! -f "$post_install_script" ]]; then
        log_info "[configuring] [$module] No post_install.sh found, skipping configuration"

        return 0
    fi

    log_info "[configuring] [$module] Running phase: post_install"
    if ! run_script "$post_install_script"; then
        log_error "[configuring] [$module] configuration failed"

        return 1
    fi

    return 0
}

#
# run_post_install <module...>
#
# Executes post_install phase for each module and collects
# per-module metadata (status, execution time) into an associative array.
#
# After execution, prints a summary table and post-install messages.
#
run_post_install() {
    local canonical_id
    local start_time_ms end_time_ms duration_ms
    local total_start_time_ms total_end_time_ms total_duration_ms

    #
    # Scan for existing messages from previous runs
    #
    delete_all_messages

    #
    # Single metadata store for all modules
    #
    declare -A metadata=()

    total_start_time_ms="$(date +%s%3N)"

    for canonical_id in "$@"; do

        #
        # Load module config into metadata
        #
        parse_module_config "$canonical_id" metadata

        start_time_ms="$(date +%s%3N)"

        __print_header \
            "$canonical_id" \
            "${metadata[$canonical_id.NAME]:-$canonical_id}" \
            "${metadata[$canonical_id.SOURCE]:-N/A}" \
            "${metadata[$canonical_id.DESCRIPTION]:-}"

        log_info "[run_configuration] Perform configuration module: $canonical_id..."

        #
        # Execute module configuration
        #
        if post_install_module "$canonical_id"; then
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
    # Summary output
    #
    printf -- '-= Configuration Summary =- [time: %s seconds]\n' "$total_duration"

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

        printf "%2d. [%s%s%s] %s ${COLOR_YELLOW}[id: %s]${COLOR_RESET} %s[%s: %s second(s)]${COLOR_RESET}\n" \
            "$index" \
            "$status_color" "$icon" "$COLOR_RESET" \
            "$name" \
            "$canonical_id" \
            "$status_color" "$status" \
            "${metadata[$canonical_id.time]:-0.000}"

        if has_messages "$canonical_id"; then
            print_messages "$canonical_id"
            printf '\n'
        fi
    done

    delete_all_messages
}
