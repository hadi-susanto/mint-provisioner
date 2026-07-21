#!/usr/bin/env bash
set -euo pipefail

# muCommander didn't install to system PATH
BINARY="/opt/mucommander/bin/muCommander"
[[ -f "$BINARY" ]]
