#!/usr/bin/env bash
set -euo pipefail

PHOTOS_DIR="original-photos"
TRIPS_DIR="trips"
MAX_WIDTH=2000
QUALITY=85

# Nothing to do if original-photos/ doesn't exist or is empty
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

# --- Extract GPS coordinates from raw photos (before stripping metadata) ---
extract_gps=false
if command -v exiftool &>/dev/null; then
    extract_gps=true
fi

for trip_dir in "$PHOTOS_DIR"/*/; do
    slug="$(basename "$trip_dir")"
    out_dir="$TRIPS_DIR/$slug"
    mkdir -p "$out_dir"

    # Extract GPS data to JSON for map display
    if [ "$extract_gps" = true ]; then
        json_file="$out_dir/photo-locations.json"
        exiftool -json -n -GPSLatitude -GPSLongitude -DateTimeOriginal -FileName \
            -ext jpg -ext jpeg -ext png -ext tiff -ext heic \
            "$trip_dir" 2>/dev/null | \
        python3 -c "
import json, sys, os
try:
    data = json.load(sys.stdin)
    seen = set()
    locs = []
    for d in sorted(data, key=lambda x: x.get('DateTimeOriginal', '')):
        lat = d.get('GPSLatitude')
        lon = d.get('GPSLongitude')
        if lat is None or lon is None:
            continue
        out_name = os.path.splitext(d['FileName'])[0] + '.jpg'
        if out_name in seen:
            continue
        seen.add(out_name)
        dt = d.get('DateTimeOriginal', '')
        locs.append({'file': out_name, 'lat': lat, 'lon': lon, 'date': dt})
    if locs:
        json.dump(locs, sys.stdout, indent=2)
        sys.stdout.write('\n')
except Exception:
    pass
" > "$json_file.tmp" 2>/dev/null

        if [ -s "$json_file.tmp" ]; then
            mv "$json_file.tmp" "$json_file"
            echo "GPS data: $slug ($(python3 -c "import json; print(len(json.load(open('$json_file'))))" 2>/dev/null || echo '?') locations)"
        else
            rm -f "$json_file.tmp"
        fi
    fi

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
