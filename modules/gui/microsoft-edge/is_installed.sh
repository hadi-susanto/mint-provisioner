#!/usr/bin/env bash
set -euo pipefail

command -v microsoft-edge >/dev/null 2>&1 ||
    command -v microsoft-edge-beta >/dev/null 2>&1 ||
    command -v microsoft-edge-dev >/dev/null 2>&1 ||
    command -v microsoft-edge-canary >/dev/null 2>&1
