#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if [[ "${__STATE_LIB_LOADED:-false}" == "true" ]]; then
    return 0
fi

source "${LIB_DIR}/common.sh"

if [[ -z "${ROOT_DIR:-}" ]]; then
    log_error "[state] ROOT_DIR is not defined."

    return 1
fi

declare -A __STATES=()
readonly __STATES_DIR="$ROOT_DIR/states"
declare -a __STATE_SUDO_CMD=()

if ! can_write "$__STATES_DIR"; then
    __STATE_SUDO_CMD=(sudo)
fi

#
# Validation completed, we can mark as loaded
#
readonly __STATE_LIB_LOADED="true"

##
# Resolves the state file path for a module.
#
# The canonical ID is appended to the state storage directory and the ".env"
# suffix is added automatically.
#
# A canonical ID is expected to use the following format:
#
#     <category>/<module>
#
# This produces a state file inside the corresponding category directory.
#
# Example:
#     cli/git -> ${__STATES_DIR}/cli/git.env
#
# Arguments:
#   $1 - Module canonical ID in the form <category>/<module>.
#
# Output:
#   Prints the complete state file path.
#
# Returns:
#   0 when the canonical ID is not empty.
#   1 when the canonical ID is empty.
#
__resolve_state_file() {
    local canonical_id="${1:-}"

    if [[ -z "$canonical_id" ]]; then
        log_error "[state] Canonical ID must not be empty."

        return 1
    fi

    printf '%s/%s.env\n' "$__STATES_DIR" "$canonical_id"
}

##
# Gets a value from the in-memory state collection.
#
# If the requested key exists, its value is printed. When the key does not
# exist, a non-empty default value may be supplied. The default value is
# printed and a warning is logged.
#
# An empty default value is treated as if no default value was provided.
#
# Arguments:
#   $1 - State key.
#   $2 - Optional non-empty default value.
#
# Output:
#   Prints the stored value or the supplied default value.
#
# Returns:
#   0 when the state exists or a non-empty default value was supplied.
#   1 when the key is empty, or when the state does not exist and no non-empty
#   default value was supplied.
#
get_state() {
    local key="${1:-}"
    local default="${2:-}"

    if [[ -z "$key" ]]; then
        log_error "[get_state] State key must not be empty."

        return 1
    fi

    if [[ -n "${__STATES[$key]+_}" ]]; then
        printf '%s\n' "${__STATES[$key]}"

        return 0
    fi

    if [[ -z "$default" ]]; then
        log_error "[get_state] State does not exist: $key, no default is given!"

        return 1
    fi

    log_warn "[get_state] State does not exist: $key, returning default value: $default"
    printf '%s\n' "$default"

    return 0
}

##
# Sets a value in the in-memory state collection.
#
# The value may be empty, but the key must not be empty.
#
# Arguments:
#   $1 - State key.
#   $2 - State value.
#
# Returns:
#   0 when the state was stored successfully.
#   1 when fewer than two arguments were provided or the key is empty.
#
set_state() {
    local key="${1:-}"

    if (($# < 2)); then
        log_error "[set_state] Requires a key and a value."

        return 1
    fi

    if [[ -z "$key" ]]; then
        log_error "[set_state] State key must not be empty."

        return 1
    fi

    __STATES["$key"]="$2"

    return 0
}

##
# Saves the in-memory state collection to a module state file.
#
# The state file path is derived from the supplied module canonical ID:
#
#     <category>/<module>
#
# The corresponding category directory is created automatically when it does
# not already exist.
#
# Each state is written as an assignment to the __STATES associative array.
# Keys and values are escaped using Bash's %q format so they can later be
# restored safely by load_states.
#
# Example:
#     cli/git -> ${__STATES_DIR}/cli/git.env
#
# Arguments:
#   $1 - Module canonical ID in the form <category>/<module>.
#
# Returns:
#   0 when the category directory was created and the states were saved.
#   Non-zero when the canonical ID is empty, the directory cannot be created,
#   or the state file cannot be written.
#
save_states() {
    local canonical_id="${1:-}"
    local output_file
    local output_dir
    local key

    output_file="$(__resolve_state_file "$canonical_id")" || return $?
    output_dir="${output_file%/*}"

    if ! "${__STATE_SUDO_CMD[@]}" mkdir -p "$output_dir"; then
        log_error "[save_states] Failed to create state directory: $output_dir"

        return 1
    fi

    if ! {
        for key in "${!__STATES[@]}"; do
            printf '__STATES[%q]=%q\n' \
                "$key" \
                "${__STATES[$key]}"
        done
    } | "${__STATE_SUDO_CMD[@]}" tee "$output_file" >/dev/null; then
        log_error "[save_states] Failed to save states: $output_file"

        return 1
    fi

    return 0
}

##
# Loads a module state collection from its saved state file.
#
# The state file path is derived from the supplied module canonical ID:
#
#     <category>/<module>
#
# The current in-memory state collection is cleared before the state file is
# checked or loaded.
#
# The saved assignments are read from the file and evaluated to restore the
# __STATES associative array. If evaluation fails, the in-memory collection is
# cleared again.
#
# Arguments:
#   $1 - Module canonical ID in the form <category>/<module>.
#
# Returns:
#   0 when the state file was read and loaded successfully.
#   1 when the canonical ID is empty, the file does not exist, the file cannot
#   be read, or its content cannot be evaluated.
#
load_states() {
    local canonical_id="${1:-}"
    local state_file
    local content

    state_file="$(__resolve_state_file "$canonical_id")" || return 1

    __STATES=()

    if [[ ! -f "$state_file" ]]; then
        log_error "[load_states] State file does not exist: $state_file"

        return 1
    fi

    if ! content="$("${__STATE_SUDO_CMD[@]}" cat "$state_file")"; then
        log_error "[load_states] Failed to read state file: $state_file"

        return 1
    fi

    if [[ -n "$content" ]] && ! eval "$content"; then
        __STATES=()

        log_error "[load_states] Failed to load state file: $state_file"

        return 1
    fi

    return 0
}

##
# Deletes the saved state file for a module.
#
# The state file path is derived from the supplied module canonical ID:
#
#     <category>/<module>
#
# If the state file does not exist, the function succeeds without performing
# any action.
#
# The containing category directory is not removed, even when it becomes empty.
#
# Arguments:
#   $1 - Module canonical ID in the form <category>/<module>.
#
# Returns:
#   0 when the state file was deleted or did not exist.
#   1 when the canonical ID is empty or the file cannot be deleted.
#
delete_states() {
    local canonical_id="${1:-}"
    local state_file

    state_file="$(__resolve_state_file "$canonical_id")" || return 1

    if [[ ! -e "$state_file" ]]; then
        return 0
    fi

    log_info "[delete_states] Deleting state: $canonical_id"

    if ! "${__STATE_SUDO_CMD[@]}" rm -f "$state_file"; then
        log_error "[delete_states] Failed to delete state file: $state_file"

        return 1
    fi

    return 0
}

##
# Deletes all saved module state files.
#
# The in-memory state collection is cleared first. If the root state directory
# does not exist, the function logs a warning and succeeds without performing
# any filesystem operation.
#
# When the directory exists, it and all category subdirectories and state files
# are removed recursively.
#
# The state directory is not recreated afterward.
#
# Returns:
#   0 when the state directory was deleted or did not exist.
#   1 when the state directory cannot be deleted.
#
delete_all_states() {
    __STATES=()

    if [[ ! -e "$__STATES_DIR" ]]; then
        log_warn "[delete_all_states] State directory does not exist; states are already deleted."

        return 0
    fi

    log_info "[delete_all_states] Deleting all states"

    if ! "${__STATE_SUDO_CMD[@]}" rm -rf "$__STATES_DIR"; then
        log_error "[delete_all_states] Failed to delete state directory: $__STATES_DIR"

        return 1
    fi

    return 0
}
