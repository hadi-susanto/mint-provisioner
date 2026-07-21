#!/usr/bin/env bash

#
# Now we need module resolution and metadata for the configuration workflow.
#
source "$LIB_DIR/module_resolver.sh"
source "$LIB_DIR/metadata_parser.sh"

__print_module_row() {
    local index="$1"
    local category_id="$2"
    local module_id="$3"
    local have_post_install="$4"
    local canonical_id="$category_id/$module_id"
    local post_install_icon
    local module_alias

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

    local -a aliases=()
    local -a tags=()
    if [[ -n "${metadata[$canonical_id.SOURCE]:-}" ]]; then
        tags+=("src: ${metadata[$canonical_id.SOURCE]}")
    fi

    if ! get_module_tags "$canonical_id" tags; then
        return 1
    fi

    if ! get_module_aliases "$canonical_id" aliases; then
        return 1
    fi

    printf "%3d. [%s] %s %s[id: %s]%s" \
        "$index" \
        "$post_install_icon" \
        "${metadata[$canonical_id.NAME]:-N/A}" \
        "${COLOR_YELLOW}" "$canonical_id" "${COLOR_RESET}"

    for module_alias in "${aliases[@]}"; do
        printf " %s[alias: %s]%s" "${COLOR_YELLOW}" "$module_alias" "${COLOR_RESET}"
    done

    for tag in "${tags[@]}"; do
        printf " %s[%s]%s" "${COLOR_CYAN}" "$tag" "${COLOR_RESET}"
    done

    printf '\n'

    return 0
}

##
# Lists installed modules and optionally collects configurable module IDs.
#
# Parameters:
#   result_name    Optional name of an array that receives module IDs having a
#                  post-install phase.
#
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
    printf "  [%s] Module has a post-install phase and can be configured.\n" "${COLOR_GREEN}✓${COLOR_RESET}"
    printf "  [%s] Module does not have a post-install phase and cannot be configured.\n" "${COLOR_RED}✗${COLOR_RESET}"

    return 0
}

__print_header() {
    local canonical_id="$1"
    local name="$2"
    local source="$3"
    local description="$4"

    printf "%s\n" "----------------------------------------------------------------------"
    printf -- "-= Configuring %s =- %s[id: %s]%s %s[src: %s] [post-install]%s\n" \
        "$name" \
        "${COLOR_YELLOW}" "$canonical_id" "${COLOR_RESET}" \
        "${COLOR_CYAN}" "$source" "${COLOR_RESET}"
    printf '%s\n' "$description"
    printf "%s\n" "----------------------------------------------------------------------"
}

__print_footer() {
    local canonical_id="$1"
    local name="$2"
    local status="$3"
    local duration="$4"
    local icon
    local status_color
    local result

    if [[ "$status" == "SUCCESS" ]]; then
        icon="✔"
        status_color="$COLOR_GREEN"
        result="completed"
    else
        icon="✗"
        status_color="$COLOR_RED"
        result="failed"
    fi

    printf "%s\n" "----------------------------------------------------------------------"
    printf " %s%s%s %s %s[id: %s]%s configuration %s in %s sec(s)\n" \
        "$status_color" "$icon" "${COLOR_RESET}" \
        "$name" \
        "${COLOR_YELLOW}" "$canonical_id" "${COLOR_RESET}" \
        "$result" \
        "${duration}"
}

##
# Runs post-install configuration for an installed module when available.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#
# Returns:
#   1 when the post-install phase runs and fails. Missing installations or
#   post-install phases are skipped successfully.
#
post_install_module() {
    local canonical_id="$1"
    local module_dir="$MODULES_DIR/$canonical_id"
    local is_installed_script="$module_dir/is_installed.sh"
    local post_install_script="$module_dir/post_install.sh"

    log_info "[configuring] [$canonical_id] Checking installation status..."

    # Use run_script directly. non-zero return (like 1) means not installed or error.
    if ! run_script "$is_installed_script" "CANONICAL_ID" "$canonical_id" >/dev/null 2>&1; then
        log_info "[configuring] [$canonical_id] Not installed or check failed, skipping"

        return 0
    fi

    if [[ ! -f "$post_install_script" ]]; then
        log_info "[configuring] [$canonical_id] No post_install.sh found, skipping configuration"

        return 0
    fi

    log_info "[configuring] [$canonical_id] Running phase: post_install"
    if ! run_script "$post_install_script" "CANONICAL_ID" "$canonical_id"; then
        log_error "[configuring] [$canonical_id] configuration failed"

        return 1
    fi

    return 0
}

##
# Configures modules, prints their results, and processes stored messages.
#
# Parameters:
#   modules    Canonical module IDs to configure.
#
# Returns:
#   1 when any module configuration or final message cleanup fails.
#
run_post_install() {
    local canonical_id
    local start_time_ms end_time_ms duration_ms
    local total_start_time_ms total_end_time_ms total_duration_ms
    local exit_status=0

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
            exit_status=1
        fi

        end_time_ms="$(date +%s%3N)"
        duration_ms=$((end_time_ms - start_time_ms))

        printf -v duration '%d.%03d' \
            "$((duration_ms / 1000))" \
            "$((duration_ms % 1000))"

        metadata["$canonical_id.time"]="$duration"

        __print_footer \
            "$canonical_id" \
            "${metadata[$canonical_id.NAME]:-$canonical_id}" \
            "${metadata[$canonical_id.status]}" \
            "$duration"

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

        printf "%2d. [%s] %s %s[id: %s]%s %s[%s: %s sec(s)]%s\n" \
            "$index" \
            "${status_color}${icon}${COLOR_RESET}" \
            "$name" \
            "${COLOR_YELLOW}" "$canonical_id" "${COLOR_RESET}" \
            "$status_color" "$status" \
            "${metadata[$canonical_id.time]:-0.000}" "${COLOR_RESET}"

        if has_messages "$canonical_id"; then
            print_messages "$canonical_id" 4
        fi
    done

    if ! delete_all_messages; then
        exit_status=1
    fi

    return "$exit_status"
}
