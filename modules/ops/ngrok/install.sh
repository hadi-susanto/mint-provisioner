#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" ngrok || exit $?

message="ngrok installed successfully.

Add your authtoken from the ngrok dashboard, then share a local port:
    ngrok config add-authtoken <token>
    ngrok http 3000

Guide: https://ngrok.com/use-cases/share-localhost"

add_message "$CANONICAL_ID" "info" "$message"
