#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"

__clone_git_repository() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local repository_url="https://github.com/romkatv/powerlevel10k.git"
    local parent_dir
    local existing_entry
    local temporary_dir

    if [[ -f "$install_path/powerlevel10k.zsh-theme" ]]; then
        tlog_warn "$tag" \
            "Powerlevel10k already exists; skipping clone: %s" "$install_path"

        return 0
    fi

    if [[ -e "$install_path" && ! -d "$install_path" ]]; then
        tlog_error "$tag" \
            "Installation target exists but is not a directory: %s" "$install_path"

        return 1
    fi

    if [[ -d "$install_path" ]]; then
        if ! existing_entry="$(
            find "$install_path" -mindepth 1 -maxdepth 1 -print -quit
        )"; then
            tlog_error "$tag" \
                "Failed to inspect installation directory: %s" "$install_path"

            return 1
        fi

        if [[ -n "$existing_entry" ]]; then
            tlog_error "$tag" \
                "Installation directory is non-empty but does not contain Powerlevel10k: %s" \
                "$install_path"

            return 1
        fi
    fi

    parent_dir="$(dirname -- "$install_path")" || return 1

    if ! mkdir -p "$parent_dir"; then
        tlog_error "$tag" \
            "Failed to create installation parent directory: %s" "$parent_dir"

        return 1
    fi

    if ! temporary_dir="$(
        mktemp -d "$parent_dir/.powerlevel10k.XXXXXX"
    )"; then
        tlog_error "$tag" "Failed to create a temporary clone directory"

        return 1
    fi

    tlog_info "$tag" "Cloning git repository: %s" "$repository_url"

    if ! git clone --depth 1 "$repository_url" "$temporary_dir"; then
        tlog_error "$tag" \
            "Failed to clone Powerlevel10k from: %s" "$repository_url"
        rm -rf -- "$temporary_dir"

        return 2
    fi

    if [[ ! -f "$temporary_dir/powerlevel10k.zsh-theme" ]]; then
        tlog_error "$tag" \
            "Cloned repository does not contain the Powerlevel10k theme"
        rm -rf -- "$temporary_dir"

        return 3
    fi

    if [[ -d "$install_path" ]] && ! rmdir -- "$install_path"; then
        tlog_error "$tag" \
            "Installation directory is no longer empty: %s" "$install_path"
        rm -rf -- "$temporary_dir"

        return 1
    fi

    if ! mv -- "$temporary_dir" "$install_path"; then
        tlog_error "$tag" \
            "Failed to move Powerlevel10k into: %s" "$install_path"
        rm -rf -- "$temporary_dir"

        return 1
    fi
}

__generate_installation_messages() {
    local canonical_id="$1"
    local install_path="$2"
    local message

    printf -v install_path_literal '%q' "$install_path"
    printf -v theme_file_literal '%q' "$install_path/powerlevel10k.zsh-theme"

    message="To enable Powerlevel10k through System Toolkit, run:

  POWERLEVEL10K_INSTALL_DIR=$install_path_literal syskit-cfg install term/power-level-10k

Without System Toolkit, add the following to your Zsh configuration:

  source $theme_file_literal"
    
    if ! add_message "$canonical_id" info "$message"; then
        tlog_warn "install:$canonical_id" "Failed to persist Powerlevel10k integration guidance"
    fi

    if command -v zsh >/dev/null 2>&1; then
        return 0
    fi

    message="Zsh is not installed. Install it before enabling Powerlevel10k.
You can install Zsh using Mint Provisioner: 'mp install term/zsh'"

    tlog_warn "install:$canonical_id" "Zsh is not installed; Powerlevel10k requires it"

    if ! add_message "$canonical_id" warn "$message"; then
        tlog_warn "install:$canonical_id" "Failed to persist the missing-Zsh warning"
    fi
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path
    local revision

    install_path="$(expand_path "$raw_install_path")" || return $?
    tlog_info "install:$canonical_id" "Installing Powerlevel10k to %s" "$install_path"

    __clone_git_repository "$canonical_id" "$install_path" || return $?
    if [[ ! -f "$install_path/powerlevel10k.zsh-theme" ]]; then
        tlog_error "install:$canonical_id" \
            "Powerlevel10k theme source was not installed: %s" \
            "$install_path/powerlevel10k.zsh-theme"

        return 3
    fi

    set_registry "INSTALL_PATH" "$install_path" || return 4

    if revision="$(git -C "$install_path" rev-parse HEAD 2>/dev/null)"; then
        set_registry "GIT_REVISION" "$revision" || return 4
    else
        tlog_warn "install:$canonical_id" "Unable to record the installed Git revision"
    fi

    if ! save_registry "$canonical_id"; then
        tlog_error "install:$canonical_id" "Failed to save the installation registry"

        return 4
    fi

    tlog_info "install:$canonical_id" "Installation completed successfully"

    __generate_installation_messages "$canonical_id" "$install_path"
}

main "$CANONICAL_ID" "${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"
