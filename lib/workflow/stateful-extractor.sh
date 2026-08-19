#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_EXTRACTOR_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_EXTRACTOR_LOADED=1

source "$LIB_INSTALLER/extractor.sh"
source "$LIB_INSTALLER/state.sh"

##
# stateful_extract <canonical_id> <state_name> <type> <install_dir> <extractor args...>
#
# Loads module state, resolves an archive path, and extracts it to an install directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for state loading and logging.
#   state_name - State key containing the archive path.
#   type - Archive type passed to `extract_archive`.
#   install_dir - Extraction destination directory.
#   extractor args... - Additional extractor arguments passed as-is.
#
# Return:
#   1 - Validation failed, state lookup failed, archive is missing, or extraction failed.
#
stateful_extract() {
    local canonical_id="$1"
    local state_name="$2"
    local archive_type="$3"
    local install_dir="$4"
    local tag="extract:$canonical_id"
    local archive_file

    if ! load_states "$canonical_id"; then
        tlog_error "$tag" "Failed to load state for %s" "$canonical_id"

        return 1
    fi

    if ! archive_file="$(get_state "$state_name")"; then
        tlog_error "$tag" "State key is not set: %s" "$state_name"

        return 1
    fi

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Archive state file does not exist: %s" "$archive_file"

        return 1
    fi

    shift 4

    if ! extract_archive "$canonical_id" "$archive_type" "$archive_file" "$install_dir" "$@"; then
        tlog_error "$tag" "Failed to extract state archive from key: %s" "$state_name"

        return 1
    fi

    tlog_info "$tag" "Archive extracted successfully to: %s" "$install_dir"

    return 0
}
