#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$CANONICAL_ID] Archive file $ARCHIVE_FILE not found"

    exit 2
fi

if [[ -z "${APACHE_MAVEN_INSTALL_DIR:-}" ]]; then
    APACHE_MAVEN_INSTALL_DIR="$INSTALL_DIR/apache-maven"
fi

SUDO_CMD=""
if ! can_write "$APACHE_MAVEN_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

log_info "[$CANONICAL_ID] Extracting $ARCHIVE_FILE to $APACHE_MAVEN_INSTALL_DIR"
$SUDO_CMD mkdir -p "$APACHE_MAVEN_INSTALL_DIR"

# Extract while stripping the top-level directory (e.g., apache-maven-3.9.16/)
if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$APACHE_MAVEN_INSTALL_DIR" --strip-components=1; then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 3
fi

# add_to_path takes the directory containing binaries (bin/)
add_to_path "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR}/bin"

if command -v java >/dev/null 2>&1; then
  exit 0
fi

msg="Java was not found on your system. You can install it using the SDKMAN! module: './install.sh dev/sdkman'"

log_warn "[$CANONICAL_ID] $msg"
add_message "$CANONICAL_ID" "warn" "$msg"
