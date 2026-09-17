#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_PATH_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_PATH_LOADED=1

source "$LIB_INSTALLER/messages.sh"

##
# expand_path
#
# Expands a path into an absolute, normalized path.
#
# A leading ~ refers to the current user's HOME. Other user-home forms such as
# ~other-user are not supported. Environment variables and shell expressions
# are not evaluated.
#
# Parameters:
#   path - Non-empty path to expand.
#
# Output:
#   Prints the expanded absolute path.
#
# Return:
#   1 - The path, HOME, or current working directory is invalid, or expansion
#       failed.
#
expand_path() {
    local path="$1"
    local expanded_path

    if [[ "$path" == *$'\n'* || "$path" == *$'\r'* ]]; then
        tlog_error "path" "Path must be single-line"

        return 1
    fi

    case "$path" in
        "~")
            if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
                tlog_error "path" "HOME must be set to an absolute path"

                return 1
            fi

            path="$HOME"
            ;;
        "~/"*)
            if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
                tlog_error "path" "HOME must be set to an absolute path"

                return 1
            fi

            path="$HOME/${path:2}"
            ;;
        "~"*)
            tlog_error "path" \
                "User-specific home expansion is not supported: %s" "$path"

            return 1
            ;;
    esac

    if [[ "$path" != /* ]]; then
        if [[ -z "${PWD:-}" || "$PWD" != /* ]]; then
            tlog_error "path" \
                "The current working directory must be absolute"

            return 1
        fi

        path="$PWD/$path"
    fi

    if ! expanded_path="$(realpath -m -- "$path")"; then
        tlog_error "path" "Failed to expand path: %s" "$path"

        return 1
    fi

    printf '%s\n' "$expanded_path"
}

##
# can_write <target>
#
# Checks whether an existing path is writable or a missing path can be created
# beneath its nearest existing writable ancestor.
#
# Parameters:
#   target - Existing path or prospective path to inspect.
#
# Return:
#   0 - The target is writable or can be created.
#   1 - The argument is invalid or no writable target or ancestor exists.
#
can_write() {
    local target="${1:-}"
    local directory
    local parent

    if (( $# != 1 )) || [[ -z "$target" ]]; then
        return 1
    fi

    target="$(expand_path "$target")" || return 1

    if [[ -e "$target" ]]; then
        if [[ -d "$target" ]]; then
            [[ -w "$target" && -x "$target" ]]
        else
            [[ -w "$target" ]]
        fi

        return
    fi

    directory="$(dirname -- "$target")" || return 1

    while [[ ! -d "$directory" ]]; do
        parent="$(dirname -- "$directory")" || return 1
        [[ "$parent" != "$directory" ]] || return 1
        directory="$parent"
    done

    [[ -w "$directory" && -x "$directory" ]]
}

##
# add_to_path
#
# Registers a non-empty directory in the system-wide PATH.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and the profile filename.
#   source_path - Absolute non-empty directory to add to PATH.
#
# Return:
#   0 - The system-wide PATH profile script was created.
#   1 - Validation or profile-script creation failed.
#
add_to_path() {
    local canonical_id="${1:-}"
    local source_path="${2:-}"
    local tag="path"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$source_path" ]]; then
        tlog_error "$tag" "A canonical ID and source directory are required"

        return 1
    fi

    if [[ "$source_path" != /* ]]; then
        tlog_error "$tag" "Source path must be absolute: %s" "$source_path"

        return 1
    fi

    if [[ "$source_path" == *:* || "$source_path" == *$'\n'* ||
        "$source_path" == *$'\r'* ]]; then
        tlog_error "$tag" "Source path cannot be represented safely in PATH: %s" "$source_path"

        return 1
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "$canonical_id"

        return 1
    fi

    if [[ ! -d "$source_path" ]]; then
        tlog_error "$tag" "Source path is not a directory: %s" "$source_path"

        return 1
    fi

    if [[ -z "$(ls -A -- "$source_path")" ]]; then
        tlog_error "$tag" "Source directory is empty: %s" "$source_path"

        return 1
    fi

    local normalized_id="${canonical_id//\//_}"
    local profile_script="/etc/profile.d/99-path-$normalized_id.sh"
    local content
    local escaped_path="$source_path"

    escaped_path="${escaped_path//\\/\\\\}"
    escaped_path="${escaped_path//\"/\\\"}"
    escaped_path="${escaped_path//\$/\\\$}"
    escaped_path="${escaped_path//\`/\\\`}"

    content="$(cat <<EOF
case ":\$PATH:" in
  *":${escaped_path}:"*) ;;
  *) export PATH="${escaped_path}:\$PATH" ;;
esac
EOF
)"

    tlog_info "$tag" "Registering %s in %s" "$source_path" "$profile_script"

    if ! printf '%s\n' "$content" | sudo tee "$profile_script" >/dev/null; then
        tlog_error "$tag" "Failed to write PATH profile script"

        return 1
    fi

    tlog_warn "$tag" "A new login may be required before PATH changes apply"

    if ! add_message "$canonical_id" info \
        "New directory added to PATH: $source_path. Please log in again to apply changes."; then
        tlog_warn "$tag" "Failed to record the PATH update message"
    fi

    return 0
}
