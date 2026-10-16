#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_FILTER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_FILTER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_INSTALLER/detection.sh"

##
# filter_removable_modules
#
# Selects the modules that should be removed using one metadata parse and one
# detection call per module. Selector order and duplicates are preserved.
#
# Installed modules are queued. Modules that are not installed are skipped
# unless force is 1. Detection failures are logged and abort the run after
# every module has been inspected.
#
# Parameters:
#   force - 1 to queue modules even when they are not installed, 0 otherwise.
#   result_name - Name of the indexed array that receives canonical IDs.
#   names_name - Name of the associative array that receives ID-to-name pairs.
#   canonical_ids - Resolved canonical module IDs.
#
# Return:
#   1 - Metadata or detection failed for at least one module.
#   2 - The arguments are invalid.
#
filter_removable_modules() {
    local force="${1:-}"
    local result_name="${2:-}"
    local names_name="${3:-}"

    if (( $# < 3 )) || [[ "$force" != "0" && "$force" != "1" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ||
        [[ ! "$names_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error \
            "Module filtering requires a force value of 0 or 1, a result array and a names array"

        return 2
    fi

    shift 3

    local -n result_ref="$result_name"
    local -n names_ref="$names_name"
    local -A metadata=()
    local canonical_id
    local module_name
    local failed=0
    local status
    local joined
    local -a queued=()
    local -a skipped=()

    result_ref=()
    names_ref=()

    tlog_info "removal" "Verifying module installation status..."
    for canonical_id in "$@"; do
        metadata=()

        if ! parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
            tlog_error "removal:$canonical_id" \
                "Unable to load module metadata: %s" "$canonical_id"
            failed=1

            continue
        fi

        module_name="${metadata[NAME]}"
        names_ref["$canonical_id"]="$module_name"

        if module_installed "$canonical_id" metadata; then
            status=0
        else
            status=$?
        fi

        if (( status > 1 )); then
            tlog_error "removal:$canonical_id" \
                "Installed-state detection failed for %s (status: %d)" \
                "$module_name" "$status"
            failed=1

            continue
        fi

        if (( status == 0 || force )); then
            result_ref+=("$canonical_id")
            queued+=("$module_name")

            continue
        fi

        skipped+=("$module_name")
    done

    if (( failed )); then
        tlog_error "removal" \
            "Removal was aborted. Please review the logs above for more details."

        return 1
    fi

    if (( ${#queued[@]} > 0 )); then
        joined=$(printf '%s, ' "${queued[@]}")
        tlog_info "removal" "Queued for removal: %s" "${joined%, }"
    fi

    if (( ${#skipped[@]} > 0 )); then
        joined=$(printf '%s, ' "${skipped[@]}")
        tlog_info "removal" "Skipped because not installed: %s" "${joined%, }"
    fi

    return 0
}
