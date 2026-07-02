#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="apache-maven"
STATE_FILE="${STATE_DIR}/${MODULE}.path"

if [[ -z "${APACHE_MAVEN_INSTALL_DIR:-}" ]]; then
    APACHE_MAVEN_INSTALL_DIR="$INSTALL_DIR/apache-maven"
fi

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file $STATE_FILE not found"

    exit 1
fi

read -r ARCHIVE_FILE < "$STATE_FILE"

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$MODULE] Archive file $ARCHIVE_FILE not found"

    exit 2
fi

SUDO_CMD=""
if ! can_write "$(dirname "$APACHE_MAVEN_INSTALL_DIR")"; then
    SUDO_CMD="sudo"
fi

log_info "[$MODULE] Extracting $ARCHIVE_FILE to $APACHE_MAVEN_INSTALL_DIR"
$SUDO_CMD mkdir -p "$APACHE_MAVEN_INSTALL_DIR"

# Extract while stripping the top-level directory (e.g., apache-maven-3.9.16/)
if ! $SUDO_CMD tar -xzf "$ARCHIVE_FILE" -C "$APACHE_MAVEN_INSTALL_DIR" --strip-components=1; then
    log_error "[$MODULE] Extraction failed"

    exit 3
fi

# add_to_path takes the directory containing binaries (bin/)
# However, many modules here seem to register the base directory if it contains bin/
# Looking at add_to_path in installer_common.sh, it just adds the path to PATH.
# Maven's executable is in bin/
add_to_path "$MODULE" "${APACHE_MAVEN_INSTALL_DIR}/bin"

if command -v java >/dev/null 2>&1; then
  exit 0
fi

log_warn "[$MODULE] Java not found. Maven requires Java to run."
post_message "$MODULE" "Java was not found on your system. You can install it using the sdkman module from mint-provisioner: './install.sh sdkman'"
