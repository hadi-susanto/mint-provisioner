#!/usr/bin/env bash

for binary in \
    mkvextract \
    mkvinfo \
    mkvmerge \
    mkvpropedit
do
    command -v "$binary" >/dev/null 2>&1 || exit 1
done

if [[ "${MKVTOOLNIX_GUI_ENABLED:-false}" == "true" ]]; then
    command -v mkvtoolnix-gui >/dev/null 2>&1 || exit 1
fi

exit 0
