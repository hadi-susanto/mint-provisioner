#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

install_path="$(expand_path "${ANDROID_STUDIO_INSTALL_DIR:-$INSTALL_DIR/android-studio}")" || exit $?

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.gz" \
    "$install_path" \
    "bin/studio" \
    "android-studio" \
    -- \
    "--strip-components=1" || exit $?

install_desktop_entry "$CANONICAL_ID" "android-studio" "Android Studio" "$(symlink_location)/android-studio" \
    --exec-args "%f" \
    --comment "Develop Android apps with Android Studio" \
    --icon-file "$install_path/bin/studio.svg" \
    --startup-notify 1 \
    --startup-wm-class "jetbrains-studio" \
    --categories "Development;IDE;" \
    --keywords "Development;IDE;Android;Kotlin;Java;Gradle;"
