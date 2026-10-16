#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_SUDO_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_SUDO_LOADED=1

source "$LIB_COMMON/common.sh"

##
# cache_sudo_privileges
#
# Offers to cache sudo privileges so modules can invoke sudo later.
#
# Return:
#   1 - The response could not be read or sudo could not be acquired.
#
cache_sudo_privileges() {
    local response

    log_info \
        "Sudo privileges can be cached now so modules can invoke sudo when necessary."

    if ! IFS= read -r -p "Cache sudo privileges now? (Y/n): " response; then
        log_error "Unable to read the sudo privilege response"

        return 1
    fi

    response="${response:-y}"

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Acquiring sudo privileges..."

        if ! sudo -v; then
            log_error "Failed to acquire sudo privileges"

            return 1
        fi

        return 0
    fi

    log_info "Continuing without cached sudo privileges"

    return 0
}

##
# build_unattended_retry_command
#
# Builds a "sudo -v && mp <command> ..." retry line.
#
# Parameters:
#   result_name - Name of the variable that receives the command line.
#   command_name - mp command to retry, such as "install".
#   arguments - Original command arguments.
#
build_unattended_retry_command() {
    local result_name="$1"
    local command_name="$2"
    shift 2

    local -n result_ref="$result_name"
    local argument
    local quoted_argument

    result_ref="sudo -v && mp $command_name"

    for argument in "$@"; do
        printf -v quoted_argument '%q' "$argument"
        result_ref+=" $quoted_argument"
    done
}

##
# validate_sudo_privileges
#
# Verifies cached or passwordless sudo without prompting.
#
# Parameters:
#   command_name - mp command shown in the retry hint.
#   arguments - Original command arguments.
#
# Return:
#   1 - sudo would prompt for a password.
#
validate_sudo_privileges() {
    local command_name="$1"
    shift

    local retry_command

    log_info \
        "Non-interactive mode: validating cached or passwordless sudo privileges..."

    if sudo -n -v; then
        return 0
    fi

    build_unattended_retry_command retry_command "$command_name" "$@"
    log_error \
        "Non-interactive mode could not acquire sudo privileges without prompting"
    log_info "Retry after validating sudo privileges: %s" "$retry_command"

    return 1
}
