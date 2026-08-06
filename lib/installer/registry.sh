#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REGISTRY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REGISTRY_LOADED=1

source "$LIB_COMMON/common.sh"

if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
    tlog_error "registry" "HOME must be set to an absolute path"

    return 1
fi

declare -A __REGISTRY=()
__REGISTRY_CANONICAL_ID=""
readonly __REGISTRY_DIR="$HOME/.local/state/mint-provisioner/registry"

__resolve_registry_file() {
    local canonical_id="${1:-}"
    local tag="registry"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "${canonical_id:-<empty>}"

        return 2
    fi

    printf '%s/%s.registry\n' "$__REGISTRY_DIR" "$canonical_id"
}

__validate_registry_key() {
    local key="${1:-}"

    if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        tlog_error "registry" "Invalid registry key: %s" "${key:-<empty>}"

        return 2
    fi
}

__write_registry_file() {
    local registry_file="$1"
    local keys_name="$2"
    local -n keys_ref="$keys_name"
    local key

    for key in "${keys_ref[@]}"; do
        if ! printf '%s=%s\n' "$key" "${__REGISTRY[$key]}" >>"$registry_file"; then
            return 2
        fi
    done
}

##
# get_registry <key>
#
# Prints an in-memory registry value.
#
# Parameters:
#   key - Registry key to retrieve.
#
# Output:
#   Prints the stored registry value.
#
# Return:
#   0 - The registry value exists.
#   1 - The registry value does not exist.
#   2 - The argument is invalid.
#
get_registry() {
    local key="${1:-}"

    if (( $# != 1 )); then
        tlog_error "registry" "get_registry requires one key"

        return 2
    fi

    __validate_registry_key "$key" || return $?

    if [[ -v "__REGISTRY[$key]" ]]; then
        printf '%s\n' "${__REGISTRY[$key]}"

        return 0
    fi

    tlog_error "registry" "Registry value does not exist: %s" "$key"

    return 1
}

##
# set_registry <key> <value>
#
# Stores a value in the in-memory registry collection.
#
# Parameters:
#   key - Uppercase registry key.
#   value - Single-line registry value, which may be empty.
#
# Return:
#   0 - The registry value was stored in memory.
#   2 - The arguments, key, or value are invalid.
#
set_registry() {
    local key="${1:-}"
    local value="${2-}"

    if (( $# != 2 )); then
        tlog_error "registry" "set_registry requires one key and value"

        return 2
    fi

    __validate_registry_key "$key" || return $?

    if [[ "$key" == "SCHEMA_VERSION" ]]; then
        tlog_error "registry" "SCHEMA_VERSION is managed by the registry library"

        return 2
    fi

    if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
        tlog_error "registry" "Registry values must be single-line: %s" "$key"

        return 2
    fi

    __REGISTRY["$key"]="$value"
}

##
# save_registry <canonical_id>
#
# Atomically saves the in-memory registry for one module.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the registry file.
#
# Return:
#   0 - The registry was saved.
#   2 - Validation, serialization, or writing failed.
#
save_registry() {
    local canonical_id="${1:-}"
    local keys_output
    local registry_dir
    local registry_file
    local temporary_file
    local -a keys=()

    if (( $# != 1 )); then
        tlog_error "registry" "save_registry requires one canonical ID"

        return 2
    fi

    registry_file="$(__resolve_registry_file "$canonical_id")" || return $?
    registry_dir="${registry_file%/*}"

    if [[ -n "$__REGISTRY_CANONICAL_ID" && "$__REGISTRY_CANONICAL_ID" != "$canonical_id" ]]; then
        tlog_error "registry:$canonical_id" \
            "In-memory registry belongs to another module: %s" \
            "$__REGISTRY_CANONICAL_ID"

        return 2
    fi

    if [[ -L "$registry_file" ]] ||
        { [[ -e "$registry_file" ]] && [[ ! -f "$registry_file" ]]; }; then
        tlog_error "registry:$canonical_id" "Invalid registry file: %s" "$registry_file"

        return 2
    fi

    __REGISTRY_CANONICAL_ID="$canonical_id"
    __REGISTRY[SCHEMA_VERSION]=1

    if ! keys_output="$(printf '%s\n' "${!__REGISTRY[@]}" | LC_ALL=C sort)"; then
        tlog_error "registry:$canonical_id" "Failed to sort registry keys"

        return 2
    fi

    mapfile -t keys <<<"$keys_output"

    if ! mkdir -p "$registry_dir"; then
        tlog_error "registry:$canonical_id" "Failed to create registry directory: %s" "$registry_dir"

        return 2
    fi

    if ! temporary_file="$(mktemp "$registry_dir/.registry.XXXXXX")"; then
        tlog_error "registry:$canonical_id" "Failed to create a temporary registry file"

        return 2
    fi

    if ! chmod 0600 "$temporary_file"; then
        rm -f "$temporary_file"
        tlog_error "registry:$canonical_id" "Failed to secure the temporary registry file"

        return 2
    fi

    if ! __write_registry_file "$temporary_file" keys; then
        rm -f "$temporary_file"
        tlog_error "registry:$canonical_id" "Failed to serialize registry"

        return 2
    fi

    if ! mv -f "$temporary_file" "$registry_file"; then
        rm -f "$temporary_file"
        tlog_error "registry:$canonical_id" "Failed to save registry: %s" "$registry_file"

        return 2
    fi
}

##
# load_registry <canonical_id>
#
# Replaces the in-memory collection with one module's persisted registry.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the registry file.
#
# Return:
#   0 - The registry was loaded.
#   1 - No registry exists.
#   2 - The registry path or content is invalid or unreadable.
#
load_registry() {
    local canonical_id="${1:-}"
    local key
    local line
    local line_number=0
    local registry_file
    local value

    if (( $# != 1 )); then
        tlog_error "registry" "load_registry requires one canonical ID"

        return 2
    fi

    registry_file="$(__resolve_registry_file "$canonical_id")" || return $?
    __REGISTRY=()
    __REGISTRY_CANONICAL_ID="$canonical_id"

    if [[ ! -e "$registry_file" ]]; then
        return 1
    fi

    if [[ -L "$registry_file" ]] || [[ ! -f "$registry_file" ]] ||
        [[ ! -r "$registry_file" ]]; then
        tlog_error "registry:$canonical_id" "Invalid or unreadable registry file: %s" "$registry_file"

        return 2
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        (( line_number += 1 ))

        if [[ "$line" != *=* ]]; then
            tlog_error "registry:$canonical_id" "Malformed registry line: %d" "$line_number"

            return 2
        fi

        key="${line%%=*}"
        value="${line#*=}"

        __validate_registry_key "$key" || return $?

        if [[ -v "__REGISTRY[$key]" ]]; then
            tlog_error "registry:$canonical_id" "Duplicate registry key: %s" "$key"

            return 2
        fi

        if [[ "$value" == *$'\r'* ]]; then
            tlog_error "registry:$canonical_id" "Registry value must be single-line: %s" "$key"

            return 2
        fi

        __REGISTRY["$key"]="$value"
    done <"$registry_file"

    if (( line_number == 0 )) || [[ "${__REGISTRY[SCHEMA_VERSION]:-}" != "1" ]]; then
        __REGISTRY=()
        tlog_error "registry:$canonical_id" "Registry is missing required schema metadata"

        return 2
    fi
}

##
# delete_registry <canonical_id>
#
# Deletes one module's persisted registry. A missing registry is successful.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the registry file.
#
# Return:
#   0 - The registry was deleted or did not exist.
#   2 - The argument, path, or deletion is invalid.
#
delete_registry() {
    local canonical_id="${1:-}"
    local registry_file

    if (( $# != 1 )); then
        tlog_error "registry" "delete_registry requires one canonical ID"

        return 2
    fi

    registry_file="$(__resolve_registry_file "$canonical_id")" || return $?

    if [[ -L "$registry_file" ]] ||
        { [[ -e "$registry_file" ]] && [[ ! -f "$registry_file" ]]; }; then
        tlog_error "registry:$canonical_id" "Invalid registry file: %s" "$registry_file"

        return 2
    fi

    if [[ -e "$registry_file" ]] && ! rm -f "$registry_file"; then
        tlog_error "registry:$canonical_id" "Failed to delete registry: %s" "$registry_file"

        return 2
    fi
}
