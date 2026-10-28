#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

message="cloudflared installed successfully.

Authenticate with Cloudflare, then create a tunnel:
    cloudflared tunnel login

Guide: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/"

add_message "$CANONICAL_ID" "info" "$message"
