#!/usr/bin/env bash
set -euo pipefail

# Although Double Commander have 3 kind of GUI, all of them still use doublecmd as entry point
command -v doublecmd >/dev/null 2>&1
