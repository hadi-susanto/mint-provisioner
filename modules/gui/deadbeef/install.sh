#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$CANONICAL_ID] Archive file not found: $ARCHIVE_FILE"

    exit 2
fi

if [[ -z "${DEADBEEF_INSTALL_DIR:-}" ]]; then
    DEADBEEF_INSTALL_DIR="$INSTALL_DIR/deadbeef"
fi

SUDO_CMD=""
if ! can_write "$DEADBEEF_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

log_info "[$CANONICAL_ID] Extracting content to $DEADBEEF_INSTALL_DIR"

if ! $SUDO_CMD mkdir -p "$DEADBEEF_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $DEADBEEF_INSTALL_DIR"

    exit 3
fi

# Strip the archive's top-level directory, such as deadbeef-1.10.3/.
if ! $SUDO_CMD tar \
    --overwrite \
    -xjf "$ARCHIVE_FILE" \
    -C "$DEADBEEF_INSTALL_DIR" \
    --strip-components=1
then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 4
fi

EXEC_PATH="$DEADBEEF_INSTALL_DIR/deadbeef"

log_info "[$CANONICAL_ID] Creating symbolic link"

log_info "[$CANONICAL_ID] Creating symbolic links"
if [[ "$DEADBEEF_INSTALL_DIR" != "$(symlink_location)" ]]; then
    if ! symlink_binary "$CANONICAL_ID" "$EXEC_PATH"; then
        log_error "[$CANONICAL_ID] Failed to create DeaDBeeF symbolic link"

        exit 5
    fi
else
    log_info "[$CANONICAL_ID] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$CANONICAL_ID] Installing desktop file"

APPLICATION_FOLDER="/usr/share/applications"
DESKTOP_FILE="${APPLICATION_FOLDER}/deadbeef.desktop"
ICON_PATH="audio-x-generic"

for icon_file in \
    "$DEADBEEF_INSTALL_DIR/deadbeef.png" \
    "$DEADBEEF_INSTALL_DIR/icons/256x256/deadbeef.png" \
    "$DEADBEEF_INSTALL_DIR/icons/scalable/deadbeef.svg" \
    "$DEADBEEF_INSTALL_DIR/share/icons/hicolor/256x256/apps/deadbeef.png" \
    "$DEADBEEF_INSTALL_DIR/share/icons/hicolor/scalable/apps/deadbeef.svg"
do
    if [[ -f "$icon_file" ]]; then
        ICON_PATH="$icon_file"

        break
    fi
done

if ! sudo mkdir -p "$APPLICATION_FOLDER"; then
    log_error "[$CANONICAL_ID] Failed to create desktop application directory: $APPLICATION_FOLDER"

    exit 6
fi

if ! sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=DeaDBeeF
GenericName=Audio Player
Comment=Listen to music
Icon=$ICON_PATH
Exec="$EXEC_PATH" %F
StartupWMClass=deadbeef
Terminal=false
Actions=Play;Pause;Toggle-Pause;Stop;Next;Prev;
MimeType=application/ogg;audio/x-vorbis+ogg;application/x-ogg;audio/mp3;audio/prs.sid;audio/x-flac;audio/mpeg;audio/x-mpeg;audio/x-mod;audio/x-it;audio/x-s3m;audio/x-xm;audio/x-mpegurl;audio/x-scpls;application/x-cue;audio/m4a;inode/directory;
Categories=Audio;AudioVideo;Player;GTK;
Keywords=Sound;Music;Audio;Player;Musicplayer;MP3;

[Desktop Action Play]
Name=Play
Exec="$EXEC_PATH" --play

[Desktop Action Pause]
Name=Pause
Exec="$EXEC_PATH" --pause

[Desktop Action Toggle-Pause]
Name=Toggle Pause
Exec="$EXEC_PATH" --toggle-pause

[Desktop Action Stop]
Name=Stop
Exec="$EXEC_PATH" --stop

[Desktop Action Next]
Name=Next
Exec="$EXEC_PATH" --next

[Desktop Action Prev]
Name=Previous
Exec="$EXEC_PATH" --prev
EOF
then
    log_error "[$CANONICAL_ID] Failed to install desktop file"

    exit 7
fi

log_info "[$CANONICAL_ID] Installation completed successfully"
