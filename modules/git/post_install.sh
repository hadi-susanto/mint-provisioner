#!/usr/bin/env bash

#
# Git post-installation tasks
#

source "${LIB_DIR}/common.sh"

MODULE="git"
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(get_user_home)
CONFIG_DIR="${USER_HOME}/.config/mint-provisioner"
PAYLOAD_DIR="${MODULES_DIR}/${MODULE}/payload"

if [[ "${GIT_SKIP_CONFIGURE:-${SKIP_CONFIGURE:-false}}" == "true" ]]; then
    log_warn "[$MODULE] GIT_SKIP_CONFIGURE is set to true, skipping configuration"

    return 0
fi

if [[ -z "${GIT_FORCE_CONFIGURE:-}" ]]; then
    GIT_FORCE_CONFIGURE="${FORCE_CONFIGURE:-false}"
fi

#
# Copy payloads
#
log_info "[$MODULE] Copying payloads to $CONFIG_DIR"
if [[ ! -d "$CONFIG_DIR" ]]; then
    sudo -u "$TARGET_USER" mkdir -p "$CONFIG_DIR"
fi

for file in "$PAYLOAD_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        target="$CONFIG_DIR/$filename"
        if [[ ! -f "$target" ]] || [[ "$GIT_FORCE_CONFIGURE" == "true" ]]; then
            log_info "[$MODULE] Copying $file to $target"
            sudo -u "$TARGET_USER" cp "$file" "$target"
        else
          log_warn "[$MODULE] target already exists and GIT_FORCE_CONFIGURE is not true, skipping"
        fi
    fi
done

configure_shell() {
    local shell_name=$1
    local rc_file=$2
    local source_file=$3

    if ! command -v "$shell_name" >/dev/null 2>&1; then
        log_warn "[$MODULE] $shell_name is not available, skipping configuration"

        return 0
    fi

    log_info "[$MODULE] Configuring git for $shell_name"

    if [[ ! -f "$rc_file" ]]; then
        log_info "[$MODULE] Creating $rc_file"
        sudo -u "$TARGET_USER" touch "$rc_file"
    fi

    local source_line="[[ -f \"$source_file\" ]] && source \"$source_file\""

    if ! grep -Fq "$source_line" "$rc_file"; then
        log_info "[$MODULE] Adding git aliases source to $rc_file"
        echo "$source_line" | sudo -u "$TARGET_USER" tee -a "$rc_file" > /dev/null
    else
        log_warn "[$MODULE] Git aliases source already exists in $rc_file"
    fi
}

configure_shell "zsh" "${USER_HOME}/.zshrc" "${CONFIG_DIR}/git-aliases.sh"
configure_shell "bash" "${USER_HOME}/.bashrc" "${CONFIG_DIR}/git-aliases.sh"

log_info "[$MODULE] git configuration completed"
