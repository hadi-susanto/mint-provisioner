#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"
source "$LIB_REMOVER/data.sh"
source "$LIB_REMOVER/home.sh"
source "$LIB_INSTALLER/messages.sh"

package_remove "$CANONICAL_ID" \
    "docker-ce" \
    "docker-ce-cli" \
    "containerd.io" \
    "docker-buildx-plugin" \
    "docker-compose-plugin" || exit $?
remove_apt_repository "$CANONICAL_ID" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/docker" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/containerd" || exit $?
remove_registry_data_dir "$CANONICAL_ID" || exit $?
purge_home_paths "$CANONICAL_ID" "docker" || exit $?

message="Docker Engine has been removed.

The following were created or changed during installation and were not removed
(data directories are kept unless you run mp purge):

  - /etc/docker/daemon.json, if it still exists.
  - Your membership of the docker group (remove with: sudo gpasswd -d <username> docker)."

add_message "$CANONICAL_ID" "info" "$message"
