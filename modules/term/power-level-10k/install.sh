#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/registry.sh"

__clone_git_repository() {
    local canonical_id="$1"
    local install_path="$2"
    local repository_url="https://github.com/romkatv/powerlevel10k.git"

    if [[ -d "$install_path" ]]; then
        tlog_warn "install:$canonical_id" \
            "Target directory already exists; skipping clone: %s" "$install_path"

        return 0
    fi

    if ! mkdir -p "$install_path"; then
        tlog_error "install:$canonical_id" \
            "Failed to create installation directory: %s" "$install_path"

        return 1
    fi

    tlog_info "install:$canonical_id" "Cloning git repository: %s" "$repository_url"
    if ! git clone --depth 1 "$repository_url" "$install_path"; then
        tlog_error "install:$canonical_id" \
            "Failed to clone Powerlevel10k from: %s" "$repository_url"

        return 2
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
    local install_path="$2"
    local install_path_literal
    local revision
    local theme_file_literal

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
