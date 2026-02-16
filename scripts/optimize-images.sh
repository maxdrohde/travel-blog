#!/usr/bin/env bash
set -euo pipefail

PHOTOS_DIR="_photos"
TRIPS_DIR="trips"
MAX_WIDTH=1600
QUALITY=80

# Nothing to do if _photos/ doesn't exist or is empty
if [ ! -d "$PHOTOS_DIR" ]; then
    exit 0
fi

shopt -s nullglob
has_dirs=false
for d in "$PHOTOS_DIR"/*/; do
    has_dirs=true
    break
done
if [ "$has_dirs" = false ]; then
    exit 0
fi

# Find ImageMagick (only needed when there are photos to process)
if command -v magick &>/dev/null; then
    CONVERT="magick"
elif command -v convert &>/dev/null; then
    CONVERT="convert"
else
    echo "ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

processed=0
skipped=0

for trip_dir in "$PHOTOS_DIR"/*/; do
    slug="$(basename "$trip_dir")"
    out_dir="$TRIPS_DIR/$slug"
    mkdir -p "$out_dir"

    for src in "$trip_dir"*.{jpg,jpeg,png,tiff,heic,JPG,JPEG,PNG,TIFF,HEIC}; do
        [ -f "$src" ] || continue

        basename_noext="${src##*/}"
        basename_noext="${basename_noext%.*}"
        dest="$out_dir/${basename_noext}.jpg"

        # Skip if optimized version exists and is newer than source
        if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then
            skipped=$((skipped + 1))
            continue
        fi

        echo "Optimizing: $src -> $dest"
        $CONVERT "$src" \
            -resize "${MAX_WIDTH}x>" \
            -quality "$QUALITY" \
            -strip \
            "$dest"

        processed=$((processed + 1))
    done
done

if [ $processed -gt 0 ] || [ $skipped -gt 0 ]; then
    echo "Images: $processed optimized, $skipped skipped (already up to date)"
fi
