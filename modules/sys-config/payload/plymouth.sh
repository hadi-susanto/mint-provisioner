#!/usr/bin/env bash
source "$LIB_DIR/common.sh"

GRUB_FILE="/etc/default/grub"

if [[ ! -f "$GRUB_FILE" ]]; then
    log_error "$GRUB_FILE not found, skipping plymouth customization"

    exit 1
fi

# Check if it already contains the desired configuration
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=""' "$GRUB_FILE"; then
    log_info "Plymouth customization (verbose) already applied to $GRUB_FILE"

    exit 0
fi

log_info "Applying plymouth customization to $GRUB_FILE..."
# Idempotent replacement using sed
# We want to change GRUB_CMDLINE_LINUX_DEFAULT="quiet splash" to GRUB_CMDLINE_LINUX_DEFAULT=""
# We'll use sudo as required by the issue
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' "$GRUB_FILE"

log_info "Updating GRUB..."
sudo update-grub
