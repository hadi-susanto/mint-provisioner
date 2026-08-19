#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATE_LOADED=1

source "$LIB_COMMON/common.sh"

if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
    tlog_error "state" "HOME must be set to an absolute path"

    return 1
fi

declare -A __STATES=()
readonly __STATES_DIR="$HOME/.local/state/mint-provisioner/states"

__resolve_state_file() {
    local canonical_id="${1:-}"
    local tag="state"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "${canonical_id:-<empty>}"

        return 1
    fi

    printf '%s/%s.env\n' "$__STATES_DIR" "$canonical_id"
}

##
# get_state
#
# Prints an in-memory state value.
#
# Parameters:
#   key - State key to retrieve.
#
# Output:
#   Prints the stored state value.
#
# Return:
#   0 - The state exists.
#   1 - The key is invalid or no state.
#
get_state() {
    local key="$1"

    if [[ -z "$key" ]]; then
        tlog_error "state" "A non-empty state key is required"

        return 1
    fi

    if [[ -v "__STATES[$key]" ]]; then
        printf '%s\n' "${__STATES[$key]}"

        return 0
    fi

    tlog_warn "state" "State does not exist: %s" "$key"

    return 1
}

##
# set_state
#
# Stores a value in the in-memory state collection.
#
# Parameters:
#   key - Non-empty state key to store.
#   value - State value, which may be empty.
#
# Return:
#   0 - The state value was stored in memory.
#   1 - The key is empty or the argument count is invalid.
#
set_state() {
    local key="$1"
    local value="$2"

    if [[ -z "$key" || -z "$value" ]]; then
        tlog_error "state" "A non-empty state key and value are required"

        return 1
    fi

    __STATES["$key"]="$value"
}

##
# save_states
#
# Saves all in-memory states to the module's user-scoped state file.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the persisted state file.
#
# Return:
#   0 - The in-memory state collection was persisted.
#   1 - Validation, directory creation, serialization, or writing failed.
#
save_states() {
    local canonical_id="$1"
    local state_file
    local state_dir
    local temporary_file
    local key

    state_file="$(__resolve_state_file "$canonical_id")" || return $?
    state_dir="${state_file%/*}"

    if ! mkdir -p "$state_dir"; then
        tlog_error "state:$canonical_id" "Failed to create state directory: %s" "$state_dir"

        return 1
    fi

    if ! temporary_file="$(mktemp "$state_dir/.state.XXXXXX")"; then
        tlog_error "state:$canonical_id" "Failed to create a temporary state file"

        return 1
    fi

    if ! {
        for key in "${!__STATES[@]}"; do
            printf '__STATES[%q]=%q\n' "$key" "${__STATES[$key]}"
        done
    } >"$temporary_file"; then
        rm -f "$temporary_file"
        tlog_error "state:$canonical_id" "Failed to serialize states"

        return 1
    fi

    if ! mv -f "$temporary_file" "$state_file"; then
        rm -f "$temporary_file"
        tlog_error "state:$canonical_id" "Failed to save states: %s" "$state_file"

        return 1
    fi
}

##
# load_states
#
# Replaces the in-memory collection with a module's persisted states.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the persisted state file.
#
# Return:
#   0 - The persisted state collection was loaded.
#   1 - The state file is invalid, missing, unreadable, or malformed.
#
load_states() {
    local canonical_id="$1"
    local state_file
    local content

    state_file="$(__resolve_state_file "$canonical_id")" || return $?
    __STATES=()

    if [[ ! -f "$state_file" ]]; then
        tlog_error "state:$canonical_id" "State file does not exist: %s" "$state_file"

        return 1
    fi

    if ! content="$(<"$state_file")"; then
        tlog_error "state:$canonical_id" "Failed to read state file: %s" "$state_file"

        return 1
    fi

    if [[ -n "$content" ]] && ! eval "$content"; then
        __STATES=()
        tlog_error "state:$canonical_id" "Failed to load state file: %s" "$state_file"

        return 1
    fi
}

##
# delete_states
#
# Deletes one module's persisted states. A missing file is successful.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the persisted state file.
#
# Return:
#   0 - The state file was deleted or did not exist.
#   1 - Validation or deletion failed.
#
delete_states() {
    local canonical_id="$1"
    local state_file

    __STATES=()
    state_file="$(__resolve_state_file "$canonical_id")" || return $?

    if [[ -e "$state_file" ]] && ! rm -f "$state_file"; then
        tlog_error "state:$canonical_id" "Failed to delete state file: %s" "$state_file"

        return 1
    fi

    return 0
}

##
# delete_all_states
#
# Clears in-memory states and deletes all persisted module states.
#
# Return:
#   0 - All in-memory and persisted states were deleted.
#   1 - Arguments are invalid or the state directory could not be deleted.
#
delete_all_states() {
    if (( $# != 0 )); then
        tlog_error "state" "delete_all_states does not accept arguments"

        return 1
    fi

    __STATES=()

    if [[ -e "$__STATES_DIR" ]] && ! rm -rf "$__STATES_DIR"; then
        tlog_error "state" "Failed to delete state directory: %s" "$__STATES_DIR"

        return 1
    fi
}
