#!/usr/bin/env bash
set -euo pipefail

# muCommander does not install its launcher on the system PATH.
BINARY="/opt/mucommander/bin/muCommander"
[[ -f "$BINARY" ]]
