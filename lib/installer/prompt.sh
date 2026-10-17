#!/usr/bin/env bash

# Prevent non-interactive session loading prompt.sh
if [[ -n "${NON_INTERACTIVE:-}" ]]; then
    source "$LIB_COMMON/common.sh"
    tlog_error "prompt" "Invalid module; non-interactive session attempted to load prompt.sh"

    return 1
fi

if [[ -n "${__MINT_PROVISIONER_PROMPT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_PROMPT_LOADED=1

source "$LIB_COMMON/common.sh"

if [[ -r /dev/tty && -w /dev/tty ]] &&
    { : </dev/tty; } 2>/dev/null &&
    { : >/dev/tty; } 2>/dev/null; then
    :
else
    tlog_error "prompt" "An interactive terminal is required to load the prompt library"

    return 1
fi

# Loader: selects the whiptail backend when usable, otherwise the pure-bash one.
# Both backends expose choose_option, ask_number, ask_text and ask_password with the same contract.
# Set DISABLE_WHIPTAIL=true to force the pure-bash backend.
if [[ "${DISABLE_WHIPTAIL:-false}" != "true" ]] &&
    command -v whiptail >/dev/null 2>&1 &&
    [[ -n "${TERM:-}" && "$TERM" != "dumb" ]]; then
    source "$LIB_INSTALLER/__prompt_whiptail.sh" || return $?
else
    source "$LIB_INSTALLER/__prompt_basic.sh" || return $?
fi
