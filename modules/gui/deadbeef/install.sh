#!/usr/bin/env bash
set -euo pipefail

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

application_folder="/usr/share/applications"
desktop_file="${application_folder}/deadbeef.desktop"
icon_path="$install_path/deadbeef.png"
exec_path="$install_path/deadbeef"

if ! sudo mkdir -p "$application_folder"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create desktop application directory: $application_folder"

    exit 1
fi

if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=DeaDBeeF
GenericName=Audio Player
Comment=Listen to music
Icon=$icon_path
Exec="$exec_path" %F
StartupWMClass=deadbeef
Terminal=false
Actions=Play;Pause;Toggle-Pause;Stop;Next;Prev;
MimeType=application/ogg;audio/x-vorbis+ogg;application/x-ogg;audio/mp3;audio/prs.sid;audio/x-flac;audio/mpeg;audio/x-mpeg;audio/x-mod;audio/x-it;audio/x-s3m;audio/x-xm;audio/x-mpegurl;audio/x-scpls;application/x-cue;audio/m4a;inode/directory;
Categories=Audio;AudioVideo;Player;GTK;
Keywords=Sound;Music;Audio;Player;Musicplayer;MP3;

[Desktop Action Play]
Name=Play
Exec="$exec_path" --play

[Desktop Action Pause]
Name=Pause
Exec="$exec_path" --pause

[Desktop Action Toggle-Pause]
Name=Toggle Pause
Exec="$exec_path" --toggle-pause

[Desktop Action Stop]
Name=Stop
Exec="$exec_path" --stop

[Desktop Action Next]
Name=Next
Exec="$exec_path" --next

[Desktop Action Prev]
Name=Previous
Exec="$exec_path" --prev
EOF
then
    tlog_error "install:$CANONICAL_ID" "Failed to install desktop file"

    exit 1
fi

if ! sudo chmod 0644 "$desktop_file"; then
    tlog_error "install:$CANONICAL_ID" "Failed to set desktop file permissions: $desktop_file"

    exit 1
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    if ! sudo update-desktop-database "$application_folder"; then
        tlog_warn "install:$CANONICAL_ID" "Failed to refresh the desktop application database"
    fi
fi
