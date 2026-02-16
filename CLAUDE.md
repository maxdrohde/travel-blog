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
- Each post needs YAML front matter: `title`, `date`, `description`, `image` (cover photo), `categories`
- `trips/_metadata.yml` applies shared settings (currently `toc: false`) to all posts

### Theming & Layout

- **`_quarto.yml`**: Site config — navbar, theme stack (`default` + `moving.scss`), lightbox, IBM Plex Sans font
- **`moving.scss`**: SCSS theme — warm beige background (`#faf8f5`), orange accent links (`#c4653a`)
- **`styles.css`**: Photo grid/wide layout classes, homepage listing styles, card overrides
- **`listing-home.ejs`**: EJS template for homepage — groups posts by year with date + title rows

### Photo Layout Classes

Use these Quarto divs in trip posts:

```markdown
::: {.photo-grid}          # 4-column grid (default)
::: {.photo-grid .cols-2}  # 2-column grid (also .cols-1, .cols-3, .cols-5, .cols-6)
::: {.photo-wide}          # Full-width hero image
```

All photos should use `group="trip-name"` for linked lightbox navigation and `description="..."` for lightbox captions.

### Image Optimization

- Raw photos go in `_photos/<trip-slug>/` (gitignored, not committed)
- `scripts/optimize-images.sh` runs as a Quarto pre-render hook
- Resizes to max 1600px wide, converts to JPEG quality 80, strips metadata
- Outputs optimized images to `trips/<trip-slug>/` alongside `index.qmd`
- Skips files that are already optimized and up to date
- Requires ImageMagick (`brew install imagemagick`)
- Trip posts reference images with simple relative paths: `![Caption](photo.jpg)`

### Homepage Listing

`index.qmd` uses Quarto's listing feature with `listing-home.ejs` as a custom template. Posts are sorted by date descending and rendered as year-grouped rows (not cards).
