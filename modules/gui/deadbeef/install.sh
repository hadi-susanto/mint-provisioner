#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

install_path="$(expand_path "${DEADBEEF_INSTALL_DIR:-$INSTALL_DIR/deadbeef}")" || return $?
stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.bz2" \
    "$install_path" \
    "deadbeef" \
    "deadbeef" \
    -- \
    "--strip-components=1" || exit $?

install_desktop_entry "$CANONICAL_ID" "deadbeef" "DeaDBeeF" "$install_path/deadbeef" \
    --exec-args "%F" \
    --generic-name "Audio Player" \
    --comment "Listen to music" \
    --icon "$install_path/deadbeef.png" \
    --startup-wm-class "deadbeef" \
    --categories "Audio;AudioVideo;Player;GTK;" \
    --keywords "Sound;Music;Audio;Player;Musicplayer;MP3;" \
    --mime-type "application/ogg;audio/x-vorbis+ogg;application/x-ogg;audio/mp3;audio/prs.sid;audio/x-flac;audio/mpeg;audio/x-mpeg;audio/x-mod;audio/x-it;audio/x-s3m;audio/x-xm;audio/x-mpegurl;audio/x-scpls;application/x-cue;audio/m4a;inode/directory;" \
    --action "Play|Play|--play" \
    --action "Pause|Pause|--pause" \
    --action "Toggle-Pause|Toggle Pause|--toggle-pause" \
    --action "Stop|Stop|--stop" \
    --action "Next|Next|--next" \
    --action "Prev|Previous|--prev" || exit $?
