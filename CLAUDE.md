# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Preview

```sh
quarto preview    # Local dev server with live reload
quarto render     # Build to _site/
```

No test or lint commands — this is a content site, not a software project.

## Architecture

Quarto website for a travel photography blog using a minimal "Moving"-inspired design.

### Content

- **Trip posts** live in `trips/<date-slug>/index.qmd` (e.g., `trips/2025-03-tokyo/index.qmd`)
- Each post needs YAML front matter: `title`, `date`, `description`, `image` (cover photo)
- `trips/_metadata.yml` applies shared settings (currently `toc: false`) to all posts

### Theming & Layout

- **`_quarto.yml`**: Site config — navbar, theme stack, lightbox, fonts (IBM Plex Sans body, Space Grotesk headings, IBM Plex Mono meta)
- **`moving.scss`**: Light SCSS theme — warm beige background (`#faf8f5`), orange accent links (`#c4653a`)
- **`moving-dark.scss`**: Dark SCSS theme — dark background (`#1a1a1a`), warm orange links (`#d4845a`)
- **`styles.css`**: Photo grid/strip/wide layout classes, homepage listing styles, card overrides, dark mode CSS overrides
- **`listing-home.ejs`**: EJS template for homepage — groups posts by year with date + title rows

### Photo Layout Classes

Use these Quarto divs in trip posts:

```markdown
::: {.photo-grid}              # 4-column grid (default)
::: {.photo-grid .cols-2}      # 2-column grid (also .cols-1, .cols-3, .cols-5, .cols-6)
::: {.photo-grid .grayscale}   # B&W grid, color on hover (combine with .cols-N)
::: {.photo-wide}              # Full-width hero image
::: {.photo-strip}             # Horizontal scroll strip (300px tall, snap-scroll)
```

All photos should use `group="trip-name"` for linked lightbox navigation and `description="..."` for lightbox captions.

### Trip Location Map

Each trip post can include a minimal region map at the top by adding a raw HTML div:

```html
<div class="trip-map" data-lat="48.8566" data-lng="2.3522" data-zoom="5" data-label="Paris, France"></div>
```

- Leaflet + CartoDB Positron (light) / Dark Matter (dark) tiles, loaded via CDN in `trips/_metadata.yml`
- Non-interactive (no zoom/pan/scroll) — purely visual context
- Orange circle marker + monospace label matching site accent color
- Script in `_metadata.yml` auto-initializes any `.trip-map` div on the page

### Image Comparison Slider

`img-comparison-slider` web component (~3KB) for draggable before/after photo comparisons:

```html
<img-comparison-slider>
  <img slot="first" src="before.jpg" />
  <img slot="second" src="after.jpg" />
</img-comparison-slider>
```

- CDN: `https://cdn.jsdelivr.net/npm/img-comparison-slider@8/dist/{styles.css,index.js}`
- Load the CDN links inline where needed (currently only on style reference page)
- Orange divider/handle matching site accent via CSS custom properties in `styles.css`

### Extensions

- **quarto-animate** (`_extensions/mcanouil/animate`): CSS entrance animations via `{{</* animate effect "text" */>}}` shortcode. Available globally.

### Shared Post Features

`trips/_metadata.yml` applies to all trip posts: disables TOC and injects a "← Back" arrow link at the top of each post.

### Image Optimization

- Raw photos go in `original-photos/<trip-slug>/` (gitignored, not committed)
- `scripts/optimize-images.sh` runs as a Quarto pre-render hook
- Resizes to max 1600px wide, converts to JPEG quality 80, strips metadata
- Outputs optimized images to `trips/<trip-slug>/` alongside `index.qmd`
- Skips files that are already optimized and up to date
- Requires ImageMagick (`brew install imagemagick`)
- **Must run locally** — `original-photos/` is gitignored, so the script needs a local run to produce the optimized JPEGs and GPS JSON. Commit the outputs in `trips/<slug>/`; in CI the script exits early (no `original-photos/`) and uses the committed files.
- Trip posts reference images with simple relative paths: `![Caption](photo.jpg)`

### Photo Map

Interactive map showing where trip photos were taken. To add to a trip post:

```markdown
{{</* include ../../_includes/photo-map.qmd */>}}
```

**GPS extraction** (`scripts/optimize-images.sh`):

- Extracts GPS coordinates and timestamps from raw photos via `exiftool` before ImageMagick strips metadata
- Writes `trips/<slug>/photo-locations.json` with `{file, lat, lon, date}` entries sorted chronologically
- Only processes image files (jpg, jpeg, png, tiff, heic) — skips videos
- Deduplicates by output filename (e.g., if both `.HEIC` and `.jpg` exist for same photo)
- Works automatically with iPhone photos or any GPS-enabled camera
- Requires `exiftool` (`brew install exiftool`); silently skips if not installed

**Map display** (`_includes/photo-map.qmd`):

- OJS/Leaflet map (600px tall) with CartoDB Positron (light) / Dark Matter (dark) tiles
- Orange accent circle markers matching site theme; adapts on dark mode toggle
- Dashed orange route line connecting locations in chronological order
- SVG directional arrows at segment midpoints; hidden when points are < 40px apart on screen; reposition on zoom/pan
- Photos within ~10m grouped into a single marker with a count badge overlay
- Grouped marker popup: horizontal scroll strip of thumbnails with timestamps
- Single marker popup: one thumbnail with timestamp
- Popup thumbnails open Quarto's GLightbox on click; grouped photos form a swipeable gallery
- No popup bubble chrome — transparent background, no tip arrow (`.photo-popup` class in `styles.css`)
- MutationObserver for dark mode: guards against no-op class changes (only acts on actual theme switch)
- If `photo-locations.json` is missing or empty, nothing renders — no errors

### Homepage Listing

`index.qmd` uses Quarto's listing feature with `listing-home.ejs` as a custom template. Posts are sorted by date descending and rendered as year-grouped rows (not cards).
