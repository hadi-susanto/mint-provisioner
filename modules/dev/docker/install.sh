#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

load_states "$CANONICAL_ID" || exit 1

DOCKER_LIB_INSTALL_DIR="$(
    get_state "DOCKER_LIB_INSTALL_DIR"
)" || exit 1

docker_source_dir="/var/lib/docker"
docker_config_dir="/etc/docker"
docker_config_file="${docker_config_dir}/daemon.json"
target_user="${SUDO_USER:-${USER:-}}"
__tag="install:$CANONICAL_ID"

__restart_docker_after_failure() {
    tlog_warn "$__tag" \
        "Attempting to restart Docker after configuration failure"

    if ! sudo systemctl start docker.service; then
        tlog_error "$__tag" \
            "Docker could not be restarted; check its service status manually"
    fi
}

tlog_info "$__tag" "Installing Docker Engine"

if ! apt_install \
    "$CANONICAL_ID" \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
then
    tlog_error "$__tag" "Docker package installation failed"

    exit 2
fi

#
# Docker should create this directory automatically during installation.
# Its absence does not mean that the package installation failed.
#
if [[ ! -d "$docker_source_dir" ]]; then
    message="Docker Engine was installed, but its data directory was not found:

  $docker_source_dir

The provisioner skipped Docker data migration
and did not create or modify the configured destination:

  $DOCKER_LIB_INSTALL_DIR

Check the Docker service and data-root configuration manually."

    tlog_warn "$__tag" \
        "Docker source directory not found: %s; skipping data migration" \
        "$docker_source_dir"

    add_message "$CANONICAL_ID" "warn" "$message"

    exit 0
fi

tlog_info "$__tag" \
    "Creating Docker library directory: %s" "$DOCKER_LIB_INSTALL_DIR"

if ! mkdir -p "$DOCKER_LIB_INSTALL_DIR"; then
    tlog_error "$__tag" "Failed to create Docker library directory"

    exit 3
fi

tlog_info "$__tag" "Stopping Docker service and socket"

if ! sudo systemctl stop docker.service docker.socket; then
    tlog_error "$__tag" "Failed to stop Docker"

    exit 4
fi

tlog_info "$__tag" \
    "Copying %s to %s" "$docker_source_dir" "$DOCKER_LIB_INSTALL_DIR"

if ! sudo rsync \
    --archive \
    --numeric-ids \
    "${docker_source_dir}/" \
    "${DOCKER_LIB_INSTALL_DIR}/"
then
    tlog_error "$__tag" "Failed to copy Docker library data"

    __restart_docker_after_failure

    exit 5
fi

if [[ -f "$docker_config_file" ]]; then
    message="An existing Docker configuration was found at:

  $docker_config_file

The provisioner did not modify it.
Ensure it contains the following data-root setting:

  \"data-root\": \"$DOCKER_LIB_INSTALL_DIR\"

Docker data was copied to the configured directory,
but Docker will not use it unless daemon.json points to that location."

    tlog_warn "$__tag" \
        "Existing %s found; leaving it unchanged" "$docker_config_file"

    add_message "$CANONICAL_ID" "warn" "$message"
else
    tlog_info "$__tag" "Writing Docker data-root configuration"

    if ! sudo mkdir -p "$docker_config_dir"; then
        tlog_error "$__tag" "Failed to create Docker configuration directory"

        __restart_docker_after_failure

        exit 6
    fi

    if ! sudo tee "$docker_config_file" >/dev/null <<EOF
{
  "data-root": "$DOCKER_LIB_INSTALL_DIR"
}
EOF
    then
        tlog_error "$__tag" "Failed to write Docker daemon configuration"

        __restart_docker_after_failure

        exit 7
    fi
fi

tlog_info "$__tag" "Starting Docker"

if ! sudo systemctl start docker.service; then
    tlog_error "$__tag" "Failed to start Docker"

    exit 8
fi

if ! getent group docker >/dev/null 2>&1; then
    message="The docker group was not created by the Docker package.

The provisioner did not create it or modify user group membership.
Check the Docker installation and create the group manually if required:

  sudo groupadd docker
  sudo usermod -aG docker <username>"

    tlog_warn "$__tag" \
        "Docker group does not exist; skipping user group configuration"

    add_message "$CANONICAL_ID" "warn" "$message"
elif [[ -z "$target_user" || "$target_user" == "root" ]]; then
    message="The provisioner could not determine a non-root user to add to the docker group.

Add your user manually with:

  sudo usermod -aG docker <username>"

    tlog_warn "$__tag" \
        "Unable to determine a non-root user for Docker group membership"

    add_message "$CANONICAL_ID" "warn" "$message"
elif id -nG "$target_user" |
    tr ' ' '\n' |
    grep -Fxq docker
then
    tlog_info "$__tag" \
        "User %s already belongs to the docker group" "$target_user"
else
    tlog_info "$__tag" "Adding user %s to the docker group" "$target_user"

    if ! sudo usermod -aG docker "$target_user"; then
        tlog_error "$__tag" \
            "Failed to add %s to the docker group" "$target_user"

        exit 9
    fi
fi

message="Docker Engine has been installed successfully.

Docker library directory:

  $DOCKER_LIB_INSTALL_DIR

The original $docker_source_dir directory was not removed.
After confirming that Docker is working and all existing images, containers,
and volumes are available, you may remove its old contents manually.

If your user was newly added to the docker group,
log out and sign in again before running Docker without sudo."

add_message "$CANONICAL_ID" "info" "$message"

set_registry "INSTALL_PATH" "$DOCKER_LIB_INSTALL_DIR" || exit 10
if ! save_registry "$CANONICAL_ID"; then
    tlog_error "$__tag" "Failed to save the installation registry"

    exit 10
fi

tlog_info "$__tag" "Docker installation completed successfully"
