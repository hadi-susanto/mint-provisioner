#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"

if [[ "${DNSCRYPT_PROXY_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration as requested"

    exit 0
fi

resolvconf_service="dnscrypt-proxy-resolvconf.service"

if systemctl status "$resolvconf_service" 2>&1 |
    grep -Fq "ConditionFileIsExecutable=/sbin/resolvconf was not met"
then
    log_warn \
        "[$CANONICAL_ID] $resolvconf_service cannot start because /sbin/resolvconf is unavailable"

    log_info \
        "[$CANONICAL_ID] Disabling $resolvconf_service; DNSCrypt Proxy can still be used through its systemd socket"

    if ! sudo systemctl disable "$resolvconf_service"; then
        log_error "[$CANONICAL_ID] Failed to disable $resolvconf_service"

        exit 1
    fi

    message="$resolvconf_service was disabled because /sbin/resolvconf is unavailable.

DNSCrypt Proxy can still operate through its systemd socket.
You must configure your network connection to use the DNSCrypt Proxy listening address manually."

    add_message "$CANONICAL_ID" "warn" "$message"
fi

message="DNSCrypt Proxy has been installed.

To configure your system to use it:
  1. Run 'systemctl cat dnscrypt-proxy.socket'
     check the 'ListenStream' and 'ListenDatagram' values.
  2. Open the system network configuration.
  3. Select 'Automatic (DHCP) addresses only'.
  4. Set the DNS server to the loopback address shown by the socket,
     usually '127.0.0.1' or '127.0.2.1'.

DNSCrypt Proxy configuration is available at:

  /etc/dnscrypt-proxy/dnscrypt-proxy.toml

You can change 'server_names' to select another DNS or ad-blocking provider,
such as a compatible Mullvad ad-blocking resolver."

add_message "$CANONICAL_ID" "info" "$message"
