#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"

##
# Prints the Mint Provisioner configuration directory for the target user.
#
# Returns:
#   Non-zero when the target user's home directory cannot be resolved.
#
get_config_dir() {
    local user_home
    user_home="$(get_user_home)" || return $?

    printf '%s/.config/mint-provisioner\n' "$user_home"
}

##
# Copies a payload file into the target user's configuration directory.
#
# Parameters:
#   canonical_id Canonical module ID used for logging.
#   source       Source file path.
#   force_var    Name of the module's force-configuration variable.
#
# Returns:
#   Non-zero when arguments are invalid or the directory/file operation fails.
#
copy_to_config_dir() {
    local canonical_id="${1:-}"
    local source="${2:-}"
    local force_var="${3:-}"
    local config_dir
    local filename
    local target
    local force_val

    if [[ -z "$canonical_id" || -z "$source" || -z "$force_var" ]]; then
        log_error "[copy_config] Missing required arguments"

        return 1
    fi

    force_val="${!force_var:-false}"

    if [[ ! -f "$source" ]]; then
        log_error "[copy_config] [$canonical_id] Source file $source does not exist"

        return 1
    fi

    config_dir="$(get_config_dir)" || return $?
    filename="${source##*/}"
    target="${config_dir}/${filename}"

    if [[ ! -d "$config_dir" ]]; then
        if ! mkdir -p "$config_dir"; then
            log_error "[copy_config] [$canonical_id] Failed to create directory: $config_dir"

            return 1
        fi
    fi

    if [[ ! -f "$target" ]]; then
        log_info "[copy_config] [$canonical_id] copying $source to $target"
        if ! cp "$source" "$target"; then
            log_error "[copy_config] [$canonical_id] Failed to copy $source to $target"

            return 1
        fi

        return 0
    fi

    if [[ "$force_val" == "true" ]]; then
        log_warn "[copy_config] [$canonical_id] $target already exists, overwrite file because $force_var is true"
        log_info "[copy_config] [$canonical_id] copying $source to $target"
        if ! cp "$source" "$target"; then
            log_error "[copy_config] [$canonical_id] Failed to copy $source to $target"

            return 1
        fi

        return 0
    fi

    log_warn "[copy_config] [$canonical_id] $target already exists, to overwrite existing file please set $force_var to true"
}

##
# Adds a guarded source statement to a shell startup file when needed.
#
# Parameters:
#   canonical_id   Canonical module ID used for logging.
#   shell_name     Shell executable required for the integration.
#   rc_file        Shell startup file to update.
#   source_file    Existing integration file to source.
#   caller_func    Optional public caller name used in log messages.
#
# Returns:
#   Non-zero when arguments, the source file, or the startup-file update fail.
#
__add_shell_source() {
    local canonical_id="${1:-}"
    local shell_name="${2:-}"
    local rc_file="${3:-}"
    local source_file="${4:-}"
    local caller_func="${5:-__add_shell_source}"

    if [[ -z "$canonical_id" || -z "$shell_name" || -z "$rc_file" || -z "$source_file" ]]; then
        log_error "[$caller_func] Missing required arguments"

        return 1
    fi

    if ! command -v "$shell_name" >/dev/null 2>&1; then
        log_warn "[$caller_func] [$canonical_id] $shell_name is not available, skipping configuration"

        return 0
    fi

    if [[ ! -f "$source_file" ]]; then
        log_error "[$caller_func] [$canonical_id] $source_file is not available/not a file, unable to configure $shell_name integration"

        return 1
    fi

    log_info "[$caller_func] [$canonical_id] Configuring $canonical_id for $shell_name"
    log_info "[$caller_func] [$canonical_id] Source file: $source_file"

    if [[ ! -f "$rc_file" ]]; then
        log_info "[$caller_func] [$canonical_id] Creating $rc_file"

        if ! touch "$rc_file"; then
            log_error "[$caller_func] [$canonical_id] Failed to create $rc_file"

            return 1
        fi
    fi

    local source_line="[[ -f \"$source_file\" ]] && source \"$source_file\""

    if grep -Fq "$source_line" "$rc_file"; then
        log_warn "[$caller_func] [$canonical_id] $source_file source already exists in $rc_file"

        return 0
    fi

    log_info "[$caller_func] [$canonical_id] Adding $source_file source to $rc_file"

    if ! printf '%s\n' "$source_line" >> "$rc_file"; then
        log_error "[$caller_func] [$canonical_id] Failed to update $rc_file"

        return 1
    fi
}

##
# Registers a shell-integration file in the target user's Bash RC file.
#
# Parameters:
#   canonical_id   Canonical module ID used for logging.
#   source_file    Existing integration file to source.
#
# Returns:
#   Non-zero when the target home or RC file cannot be configured.
#
add_bash_source() {
    local canonical_id="${1:-}"
    local source_file="${2:-}"
    local user_home
    user_home="$(get_user_home)" || return $?

    __add_shell_source "$canonical_id" "bash" "${user_home}/.bashrc" "$source_file" "add_bash_source"
}

##
# Registers a shell-integration file in the target user's Zsh RC file.
#
# Parameters:
#   canonical_id   Canonical module ID used for logging.
#   source_file    Existing integration file to source.
#
# Returns:
#   Non-zero when the target home or RC file cannot be configured.
#
add_zsh_source() {
    local canonical_id="${1:-}"
    local source_file="${2:-}"
    local user_home
    user_home="$(get_user_home)" || return $?

    __add_shell_source "$canonical_id" "zsh" "${user_home}/.zshrc" "$source_file" "add_zsh_source"
}

##
# Prints the directory used for installed command symbolic links.
#
symlink_location() {
    printf '%s\n' "/usr/local/bin"
}

##
# symlink_binary <canonical_id> <source_binary> [link_name]
#
# Creates a symbolic link for an executable in the shared command directory.
#
# Parameters:
#   canonical_id     Canonical module ID used for logging.
#   source_binary    Executable file to link.
#   link_name        Optional destination filename. Defaults to the source
#                    executable's filename.
#
# Returns:
#   Non-zero when arguments or the source are invalid, or linking fails.
#
symlink_binary() {
    local canonical_id="${1:-}"
    local source_binary="${2:-}"
    local link_name="${3:-${source_binary##*/}}"
    local dest_dir

    if [[ -z "$canonical_id" || -z "$source_binary" || -z "$link_name" ]]; then
        log_error "[symlink_binary] Missing required arguments"

        return 1
    fi

    if [[ "$link_name" == */* || "$link_name" == "." || "$link_name" == ".." ]]; then
        log_error "[symlink_binary] [$canonical_id] Invalid symbolic link name: $link_name"

        return 1
    fi

    dest_dir="$(symlink_location)"

    if [[ ! -f "$source_binary" ]]; then
        log_error "[symlink_binary] [$canonical_id] Source file $source_binary does not exist"

        return 1
    fi

    if [[ ! -x "$source_binary" ]]; then
        log_error "[symlink_binary] [$canonical_id] Source file $source_binary is not executable"

        return 1
    fi

    log_info \
        "[symlink_binary] [$canonical_id] Creating symbolic link: ${dest_dir}/${link_name} -> $source_binary"

    if ! sudo ln -sf "$source_binary" "${dest_dir}/${link_name}"; then
        log_error "[symlink_binary] [$canonical_id] Failed to create symbolic link"

        return 1
    fi
}

##
# Registers a non-empty executable directory in the system-wide PATH.
#
# Parameters:
#   canonical_id   Canonical module ID used for logging.
#   source_path    Directory to register.
#
# Returns:
#   Non-zero when the source is invalid or the PATH script cannot be written.
#
add_to_path() {
    local canonical_id="${1:-}"
    local source_path="${2:-}"

    if [[ -z "$canonical_id" || -z "$source_path" ]]; then
        log_error "[add_to_path] Missing required arguments"

        return 1
    fi

    if [[ ! -d "$source_path" ]]; then
        log_error "[add_to_path] [$canonical_id] Source path $source_path is not a directory"

        return 1
    fi

    # Check if directory is empty
    if [[ -z "$(ls -A "$source_path")" ]]; then
        log_error "[add_to_path] [$canonical_id] Source path $source_path is empty"

        return 1
    fi

    local normalized_canonical_id="${canonical_id//\//_}"
    local profile_script="/etc/profile.d/99-path-${normalized_canonical_id}.sh"
    log_info "[add_to_path] [$canonical_id] Registering $source_path to $profile_script"

    local content
    content="$(cat <<EOF
case ":\$PATH:" in
  *":${source_path}:"*) ;;
  *) export PATH="${source_path}:\$PATH" ;;
esac
EOF
)"

    if ! printf '%s\n' "$content" | sudo tee "$profile_script" >/dev/null; then
        log_error "[add_to_path] [$canonical_id] Failed to write $profile_script"

        return 1
    fi

    log_warn "[$canonical_id] PATH has been updated. You may need to log out and log back in for the changes to take effect."

    if ! add_message "$canonical_id" "info" "New directory added to PATH: $source_path. Please relogin to apply changes."; then
        log_warn "[add_to_path] [$canonical_id] Failed to record the PATH update message"
    fi
}
