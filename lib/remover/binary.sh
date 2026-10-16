#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_BINARY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_BINARY_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"

##
# __is_protected_directory <directory>
#
# Succeeds for directories that must never be deleted recursively.
#
__is_protected_directory() {
    local directory="$1"

    case "$directory" in
        / | /bin | /boot | /dev | /etc | /home | /lib | /lib32 | /lib64 | /media | /mnt | \
            /opt | /proc | /root | /run | /sbin | /srv | /sys | /tmp | /usr | /usr/bin | \
            /usr/lib | /usr/local | /usr/local/bin | /usr/sbin | /usr/share | /var | /var/lib)
            return 0
            ;;
        "$HOME" | "$HOME/.cache" | "$HOME/.config" | "$HOME/.local" | \
            "$HOME/.local/bin" | "$HOME/.local/share" | "$HOME/.local/state")
            return 0
            ;;
    esac

    return 1
}

##
# remove_symlink
#
# Removes a command symlink created by symlink_binary. A missing link is not
# an error; a regular file or directory at that location is never deleted.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   link_name - Symlink name that was passed to symlink_binary.
#
# Return:
#   1 - Validation failed, the destination is not a symlink, or removal failed.
#
remove_symlink() {
    local canonical_id="${1:-}"
    local link_name="${2:-}"
    local tag="remove-symlink"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$link_name" ]]; then
        tlog_error "$tag" "A canonical ID and link name are required"

        return 1
    fi

    if [[ "$link_name" == */* || "$link_name" == '.' || "$link_name" == '..' ]]; then
        tlog_error "$tag" "Invalid symlink name: %s" "$link_name"

        return 1
    fi

    local destination
    destination="$(symlink_location)/$link_name"

    if [[ ! -e "$destination" && ! -L "$destination" ]]; then
        tlog_info "$tag" "Symlink does not exist, skipping: %s" "$destination"

        return 0
    fi

    if [[ ! -L "$destination" ]]; then
        tlog_error "$tag" "Refusing to remove a path that is not a symlink: %s" "$destination"

        return 1
    fi

    tlog_info "$tag" "Removing symlink: %s" "$destination"

    if ! sudo rm -f "$destination"; then
        tlog_error "$tag" "Failed to remove symlink: %s" "$destination"

        return 1
    fi

    return 0
}

##
# remove_from_path
#
# Removes the system-wide PATH profile script created by add_to_path. A missing
# script is not an error.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and the profile filename.
#
# Return:
#   1 - Validation failed or the profile script could not be removed.
#
remove_from_path() {
    local canonical_id="${1:-}"
    local tag="remove-path"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 1 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID is required"

        return 1
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "$canonical_id"

        return 1
    fi

    local profile_script="/etc/profile.d/99-path-${canonical_id//\//_}.sh"

    if [[ ! -e "$profile_script" && ! -L "$profile_script" ]]; then
        tlog_info "$tag" "PATH profile script does not exist, skipping: %s" "$profile_script"

        return 0
    fi

    tlog_info "$tag" "Removing PATH profile script: %s" "$profile_script"

    if ! sudo rm -f "$profile_script"; then
        tlog_error "$tag" "Failed to remove PATH profile script: %s" "$profile_script"

        return 1
    fi

    if ! add_message "$canonical_id" info \
        "PATH entry removed. Please log in again to apply changes."; then
        tlog_warn "$tag" "Failed to record the PATH update message"
    fi

    return 0
}

##
# remove_install_dir
#
# Loads the module registry and deletes the installation directory recorded as
# INSTALL_PATH. A missing registry, as after an earlier removal, logs a warning
# and is not an error. Refuses relative paths, paths containing "..", symlinks,
# and protected system or home directories. Uses sudo only when the directory
# cannot be deleted as the current user.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the registry and used for logging.
#
# Return:
#   1 - The registry does not record an installation path, the path is unsafe,
#       or deletion failed.
#   2 - The registry is invalid or unreadable.
#
remove_install_dir() {
    local canonical_id="${1:-}"
    local tag="remove-install-dir"
    local install_path
    local status=0

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 1 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID is required"

        return 1
    fi

    load_registry "$canonical_id" silent || status=$?

    if (( status == 1 )); then
        tlog_warn "$tag" "No registry found; the installation directory is unknown and was not removed"

        return 0
    fi

    if (( status != 0 )); then
        return "$status"
    fi

    if ! install_path="$(get_registry INSTALL_PATH)"; then
        tlog_error "$tag" "The registry does not record an installation path"

        return 1
    fi

    while [[ "${#install_path}" -gt 1 && "$install_path" == */ ]]; do
        install_path="${install_path%/}"
    done

    if [[ "$install_path" != /* || "/$install_path/" == */../* || "/$install_path/" == */./* ]]; then
        tlog_error "$tag" "Installation path must be absolute and normalized: %s" "$install_path"

        return 1
    fi

    if __is_protected_directory "$install_path"; then
        tlog_error "$tag" "Refusing to remove a protected directory: %s" "$install_path"

        return 1
    fi

    if [[ -L "$install_path" ]] || { [[ -e "$install_path" ]] && [[ ! -d "$install_path" ]]; }; then
        tlog_error "$tag" "Installation path is not a directory: %s" "$install_path"

        return 1
    fi

    if [[ ! -d "$install_path" ]]; then
        tlog_info "$tag" "Installation directory does not exist, skipping: %s" "$install_path"

        return 0
    fi

    tlog_info "$tag" "Removing installation directory: %s" "$install_path"

    if [[ -w "${install_path%/*}" ]] && can_write "$install_path"; then
        rm -rf -- "$install_path" || status=$?
    else
        sudo rm -rf -- "$install_path" || status=$?
    fi

    if (( status != 0 )) || [[ -d "$install_path" ]]; then
        tlog_error "$tag" "Failed to remove installation directory: %s" "$install_path"

        return 1
    fi

    return 0
}
