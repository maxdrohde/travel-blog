# Travel Blog

A Quarto website for hosting travel photos, built with a minimal clean theme, responsive photo grids, and lightbox navigation.

## Structure

```
travel-blog/
├── _quarto.yml          # Site config (navbar, theme, lightbox)
├── styles/
│   ├── moving.scss      # Light SCSS theme
│   ├── moving-dark.scss # Dark SCSS theme
│   ├── styles.css       # Custom styling
│   └── listing-home.ejs # Homepage listing template
├── index.qmd            # Homepage with trip listing
└── 000-trips/
    ├── _metadata.yml    # Shared settings for trip posts
    ├── 2024-12-paris/
    │   └── index.qmd    # Example trip post
    └── 2025-03-tokyo/
        └── index.qmd    # Example trip post
```

## Adding a New Trip

Create a folder under `000-trips/` with an `index.qmd`:

```
000-trips/2025-07-iceland/index.qmd
```

With YAML front matter like:

```yaml
---
title: "Iceland Road Trip"
date: 2025-07-10
description: "Short summary here."
image: cover.jpg
categories: [Europe, Iceland]
---
```

The `image` field is the cover photo shown on the homepage grid. You can use a local file in the same folder or a URL.

## Photo Layouts

**Photo grid** — responsive multi-column layout for groups of photos:

```markdown
::: {.photo-grid}
![Caption](photo1.jpg){group="trip-name" description="Lightbox caption."}

![Caption](photo2.jpg){group="trip-name" description="Lightbox caption."}
:::
```

**Wide photo** — full-width hero image:

```markdown
::: {.photo-wide}
![Caption](hero.jpg){group="trip-name" description="Lightbox caption."}
:::
```

The `group` attribute links photos together in the lightbox so you can navigate between them with arrows. Use the same group name for all photos in a trip.

## Image Optimization

Raw photos are automatically resized and compressed before the site builds. Drop originals into `_photos/<trip-slug>/` and the pre-render script handles the rest.

```
_photos/2025-07-iceland/hero.jpg      # Raw original (gitignored)
  → 000-trips/2025-07-iceland/hero.jpg    # Optimized JPEG (committed)
```

- Max width: 1600px (aspect ratio preserved, no upscaling)
- Format: JPEG quality 80, metadata stripped
- Supports: jpg, jpeg, png, tiff, heic
- Skips already-optimized files (based on modification time)
- Requires [ImageMagick](https://imagemagick.org/): `brew install imagemagick`

The script runs automatically via Quarto's `pre-render` hook, or manually:

```sh
bash scripts/optimize-images.sh
```

## Handdrawn Content

Add handdrawn elements like trip schedules, itineraries, or sketches — either exported from GoodNotes on iPad or scanned from paper. Drop them into the trip folder alongside photos and include them in posts like any other image.

## Development

Preview the site locally:

```sh
quarto preview
```

Build the site to `_site/`:

```sh
quarto render
```
