#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/term/oh-my-posh/downloader.sh"

valid_install_target "$CANONICAL_ID" "${OH_MY_POSH_INSTALL_DIR:-$INSTALL_DIR/oh-my-posh}" "OH_MY_POSH_INSTALL_DIR" || exit $?
oh_my_posh_download "$CANONICAL_ID"
