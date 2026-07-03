#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="du-analyzer"
STATE_FILE="${STATE_DIR}/du-analyzer.path"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found: $STATE_FILE"

    exit 1
fi

read -r ARCHIVE_FILE < "$STATE_FILE"

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$MODULE] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${DU_ANALYZER_INSTALL_DIR:-}" ]]; then
    DU_ANALYZER_INSTALL_DIR="$INSTALL_DIR/du-analyzer"
fi

SUDO_CMD=""
if ! can_write "$(dirname "$DU_ANALYZER_INSTALL_DIR")"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$DU_ANALYZER_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $DU_ANALYZER_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$DU_ANALYZER_INSTALL_DIR" --strip-components=1; then
    log_error "[$MODULE] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$DU_ANALYZER_INSTALL_DIR/dua"; then
    log_error "[$MODULE] Failed to make binary executable"

    exit 5
fi

log_info "[$MODULE] Creating symbolic links"
if [[ "$DU_ANALYZER_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$MODULE" "$DU_ANALYZER_INSTALL_DIR/dua"
else
    log_info "[$MODULE] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$MODULE] Installation completed successfully"
