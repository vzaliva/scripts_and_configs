#!/bin/sh

set -e

DEST="/Volumes/Vault/"

SRC_CATALOG="$HOME/Pictures/Lightroom"
SRC_MASTERS="$HOME/Pictures/Lightroom Masters"
SRC_MOBILE_DL="$HOME/Pictures/Lightroom/Mobile Downloads.lrdata"

mkdir -p "$DEST/Lightroom" "$DEST/Lightroom Masters"

# 1) Catalogue (exclude all *.lrdata caches)
rsync -avh --delete --delete-excluded \
  --exclude='*.lrdata' \
  "$SRC_CATALOG/" \
  "$DEST/Lightroom/"

# 1a) Explicitly include Mobile Downloads.lrdata if it exists (it may hold originals)
if [ -d "$SRC_MOBILE_DL" ]; then
  rsync -avh --delete \
    "$SRC_MOBILE_DL/" \
    "$DEST/Lightroom/Mobile Downloads.lrdata/"
fi

# 2) Originals (Masters)
if [ -d "$SRC_MASTERS" ]; then
  rsync -avh --delete \
    "$SRC_MASTERS/" \
    "$DEST/Lightroom Masters/"
fi



