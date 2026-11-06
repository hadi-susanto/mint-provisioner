#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-binary-install.sh"

stateful_binary_install \
    "$CANONICAL_ID" \
    "BINARY_FILE" \
    "${KUBECTL_INSTALL_DIR:-$INSTALL_DIR/kubectl}" \
    "kubectl" || exit $?

message="To enable kubectl shell completion through System Toolkit, run:
  syskit-cfg install cli/kubectl

Without System Toolkit, add the following to your shell configuration:
  Bash: source <(kubectl completion bash)
  Zsh:  source <(kubectl completion zsh)"

if ! add_message "$CANONICAL_ID" info "$message"; then
    tlog_warn "install:$CANONICAL_ID" "Failed to persist kubectl integration guidance"
fi
