#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://ngrok-agent.s3.amazonaws.com/ngrok.asc" \
    "https://ngrok-agent.s3.amazonaws.com" \
    "bookworm" \
    "main"
