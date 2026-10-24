#!/usr/bin/env bash
set -euo pipefail

# Installs Mint Provisioner into ./mint-provisioner and puts 'mp' on the PATH:
#   curl -fsSL https://raw.githubusercontent.com/hadi-susanto/mint-provisioner/main/bootstrap.sh | bash
#
# Set MP_BRANCH to clone another branch than the default, for example to try
# an unmerged branch (fetch the script from that branch too):
#   curl -fsSL https://raw.githubusercontent.com/hadi-susanto/mint-provisioner/<branch>/bootstrap.sh |
#       MP_BRANCH=<branch> bash
#
# This script runs before the repository exists, so it cannot source the
# framework libraries. Its log helpers mirror lib/common/common.sh.

readonly __REPO_SLUG="hadi-susanto/mint-provisioner"
readonly __SSH_URL="git@github.com:${__REPO_SLUG}.git"
readonly __HTTPS_URL="https://github.com/${__REPO_SLUG}.git"
readonly __TARGET_DIR="$PWD/mint-provisioner"
readonly __BRANCH="${MP_BRANCH:-}"
readonly __COMMAND_LINK="/usr/local/bin/mp"
readonly __COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
readonly __BASH_COMPLETION_SCRIPT="/usr/share/bash-completion/bash_completion"

# Required command -> Debian package that provides it.
readonly -A __DEPENDENCIES=(
    [git]="git"
    [jq]="jq"
    [aria2c]="aria2"
    [curl]="curl"
)

if [[ -t 2 ]]; then
    readonly __COLOR_BLUE=$'\033[0;34m'
    readonly __COLOR_YELLOW=$'\033[0;33m'
    readonly __COLOR_RED=$'\033[0;31m'
    readonly __COLOR_RESET=$'\033[0m'
else
    readonly __COLOR_BLUE=''
    readonly __COLOR_YELLOW=''
    readonly __COLOR_RED=''
    readonly __COLOR_RESET=''
fi

__log() {
    local level="$1"
    local color="$2"
    local format="$3"
    shift 3

    printf '%b[%s]%b ' "$color" "$level" "$__COLOR_RESET" >&2
    # shellcheck disable=SC2059 # The format string is supplied by this script.
    printf "$format\n" "$@" >&2
}

log_info() {
    __log "INFO" "$__COLOR_BLUE" "$@"
}

log_warn() {
    __log "WARN" "$__COLOR_YELLOW" "$@"
}

log_error() {
    __log "ERROR" "$__COLOR_RED" "$@"
}

__check_environment() {
    if (( EUID == 0 )); then
        log_error "Do not run the bootstrap with sudo or as root"
        log_error "It asks for sudo itself when needed; running as root installs mp for root's \$HOME"

        return 1
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        log_error "apt-get not found; Mint Provisioner supports Linux Mint and Ubuntu only"

        return 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo not found; it is required to install dependencies and link mp"

        return 1
    fi
}

__install_dependencies() {
    local command_name
    local package
    local -a missing=()

    log_info "Checking dependencies..."

    for command_name in git jq aria2c curl; do
        package="${__DEPENDENCIES[$command_name]}"

        if command -v "$command_name" >/dev/null 2>&1; then
            log_info "Found %s" "$command_name"
        else
            log_info "Missing %s (package: %s)" "$command_name" "$package"
            missing+=("$package")
        fi
    done

    if [[ -f "$__BASH_COMPLETION_SCRIPT" ]]; then
        log_info "Found bash-completion"
    else
        log_info "Missing bash-completion (package: bash-completion)"
        missing+=("bash-completion")
    fi

    if (( ${#missing[@]} == 0 )); then
        log_info "All dependencies are installed"

        return 0
    fi

    log_info "Installing %s (sudo may ask for your password)..." "${missing[*]}"

    if ! sudo apt-get update; then
        log_error "Failed to update the APT package index"

        return 1
    fi

    if ! sudo apt-get install -y "${missing[@]}"; then
        log_error "Failed to install: %s" "${missing[*]}"

        return 1
    fi

    log_info "Dependencies installed"
}

##
# __choose_clone_url
#
# Prints the SSH clone URL when an SSH key is authorized for GitHub, otherwise
# the HTTPS URL. GitHub's host key is accepted on first contact.
#
__choose_clone_url() {
    local output

    log_info "Choosing clone protocol..."

    if ! command -v ssh >/dev/null 2>&1; then
        log_info "ssh not found; using HTTPS"
        printf '%s\n' "$__HTTPS_URL"

        return 0
    fi

    # GitHub closes the session after authenticating, so ssh exits 1 on success.
    output="$(ssh -T \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        git@github.com </dev/null 2>&1)" || true

    if [[ "$output" == *"successfully authenticated"* ]]; then
        log_info "GitHub SSH key found; using SSH"
        printf '%s\n' "$__SSH_URL"

        return 0
    fi

    log_info "No GitHub SSH access; using HTTPS"
    printf '%s\n' "$__HTTPS_URL"
}

__fetch_repository() {
    local clone_url
    local origin_url
    local -a clone_args=()

    log_info "Fetching repository into %s..." "$__TARGET_DIR"

    if [[ ! -e "$__TARGET_DIR" ]]; then
        clone_url="$(__choose_clone_url)"

        if [[ -n "$__BRANCH" ]]; then
            log_info "Using branch %s" "$__BRANCH"
            clone_args+=(--branch "$__BRANCH")
        fi

        if ! git clone "${clone_args[@]}" "$clone_url" "$__TARGET_DIR" </dev/null; then
            log_error "Failed to clone %s" "$clone_url"

            return 1
        fi

        log_info "Cloned %s" "$clone_url"

        return 0
    fi

    origin_url="$(git -C "$__TARGET_DIR" config --get remote.origin.url 2>/dev/null)" || origin_url=""

    if [[ ! -d "$__TARGET_DIR/.git" || "$origin_url" != *"$__REPO_SLUG"* ]]; then
        log_error "%s exists but is not a Mint Provisioner clone; move it away and try again" "$__TARGET_DIR"

        return 1
    fi

    log_info "Existing clone found; updating branch %s" \
        "$(git -C "$__TARGET_DIR" branch --show-current 2>/dev/null || true)"

    if [[ -n "$__BRANCH" ]]; then
        log_warn "MP_BRANCH is ignored for an existing clone; switch branches with git if needed"
    fi

    if ! git -C "$__TARGET_DIR" pull --ff-only </dev/null; then
        log_error "Failed to update %s; resolve it with git and try again" "$__TARGET_DIR"

        return 1
    fi
}

__link_command() {
    local target="$__TARGET_DIR/mp"
    local current

    log_info "Linking %s -> %s..." "$__COMMAND_LINK" "$target"

    if [[ -L "$__COMMAND_LINK" ]]; then
        current="$(readlink -f -- "$__COMMAND_LINK")" || current=""

        if [[ "$current" == "$(readlink -f -- "$target")" ]]; then
            log_info "%s already points to this installation" "$__COMMAND_LINK"

            return 0
        fi

        log_warn "Replacing existing link %s -> %s" "$__COMMAND_LINK" "$current"
    elif [[ -e "$__COMMAND_LINK" ]]; then
        log_error "%s exists and is not a symlink; remove it and try again" "$__COMMAND_LINK"

        return 1
    fi

    if ! sudo ln -sfn "$target" "$__COMMAND_LINK"; then
        log_error "Failed to create %s" "$__COMMAND_LINK"

        return 1
    fi

    log_info "Linked %s" "$__COMMAND_LINK"
}

__setup_completion() {
    local link="$__COMPLETION_DIR/mp"

    log_info "Setting up shell completion..."

    if ! mkdir -p "$__COMPLETION_DIR" ||
        ! ln -sfn "$__TARGET_DIR/completion/mp.bash" "$link"; then
        log_warn "Could not link bash completion at %s; see README.md to set it up manually" "$link"

        return 0
    fi

    log_info "Bash completion linked at %s" "$link"

    if [[ "${SHELL##*/}" == "zsh" ]]; then
        log_info "For zsh, add these lines to ~/.zshrc before any existing compinit:"
        log_info "  fpath=(%s/completion \$fpath)" "$__TARGET_DIR"
        log_info "  autoload -Uz compinit && compinit"
    fi
}

main() {
    log_info "Installing Mint Provisioner"

    __check_environment || return $?
    __install_dependencies || return $?
    __fetch_repository || return $?
    __link_command || return $?
    __setup_completion

    log_info "Mint Provisioner is installed in %s" "$__TARGET_DIR"
    log_info "Open a new terminal for tab completion, then try: mp list modules"
}

main "$@"
