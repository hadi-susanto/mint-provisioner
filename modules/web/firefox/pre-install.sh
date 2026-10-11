#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

PIN_FILE="/etc/apt/preferences.d/mozilla.pref"

# Pin before the repository is added so the first package-index refresh and the
# installation already prefer Mozilla's packages over the distribution's. The
# second stanza blocks Ubuntu's transitional firefox packages (snap stubs) so apt
# never falls back to them; Mint's own Firefox (o=linuxmint) is outranked by the
# first stanza.
log_info "[$CANONICAL_ID] Pinning packages.mozilla.org above the system package"

if ! sudo mkdir -p "$(dirname "$PIN_FILE")"; then
    log_error "[$CANONICAL_ID] Failed to create APT preferences directory"

    exit 1
fi

if ! sudo tee "$PIN_FILE" >/dev/null <<'EOF_PIN'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
EOF_PIN
then
    log_error "[$CANONICAL_ID] Failed to write APT pin: $PIN_FILE"

    exit 2
fi

if ! sudo chmod 0644 "$PIN_FILE"; then
    log_error "[$CANONICAL_ID] Failed to set APT pin permissions: $PIN_FILE"

    exit 3
fi

install_asc_key \
    "$CANONICAL_ID" \
    "https://packages.mozilla.org/apt/repo-signing-key.gpg" \
    "https://packages.mozilla.org/apt" \
    "mozilla" \
    "main" \
    "mozilla"
