---
name: Kinetic Shiori
colors:
  surface: '#fcf9ef'
  surface-dim: '#dcdad0'
  surface-bright: '#fcf9ef'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f4ea'
  surface-container: '#f1eee4'
  surface-container-high: '#ebe8de'
  surface-container-highest: '#e5e2d9'
  on-surface: '#1c1c16'
  on-surface-variant: '#594139'
  inverse-surface: '#31312a'
  inverse-on-surface: '#f4f1e7'
  outline: '#8d7168'
  outline-variant: '#e1bfb4'
  surface-tint: '#ab3600'
  primary: '#a73400'
  on-primary: '#ffffff'
  primary-container: '#cc4811'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb59c'
  secondary: '#615e59'
  on-secondary: '#ffffff'
  secondary-container: '#e8e1db'
  on-secondary-container: '#68645f'
  tertiary: '#605b52'
  on-tertiary: '#ffffff'
  tertiary-container: '#79746a'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#822700'
  secondary-fixed: '#e8e1db'
  secondary-fixed-dim: '#cbc5c0'
  on-secondary-fixed: '#1d1b18'
  on-secondary-fixed-variant: '#494642'
  tertiary-fixed: '#e9e2d5'
  tertiary-fixed-dim: '#cdc6ba'
  on-tertiary-fixed: '#1e1b14'
  on-tertiary-fixed-variant: '#4a463d'
  background: '#fcf9ef'
  on-background: '#1c1c16'
  surface-variant: '#e5e2d9'
typography:
  headline-xl:
    fontFamily: Manrope
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Manrope
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
This design system pairs the physical discipline of Japanese print editorial layout with the fluidity of modern media streaming. Tailored for voracious multi-format readers switching seamlessly between serialized manga, translated web novels, and ambient audiobooks, the interface recedes to let cover artwork and literature take precedence.

The design language draws directly from high-end Tokyo publishing houses and minimalist e-ink hardware:
- **Tactile Paper Roots:** Rather than harsh sterile whites, surfaces echo natural unbleached washi and pressed cream stock, softening ocular fatigue during marathon reading sessions.
- **Editorial Precision:** Strict alignment, balanced vertical typographic cadence, and hairline dividers ground the interface, avoiding the cluttered, neon gamification common to standard webtoon hubs.
- **Inkwash Dynamism:** Primary accents reflect traditional Japanese cinnabar ink (*shu-iro*), reserved strictly for focal points: reading progress, live playback scrubbing, and critical transactional states.

## Colors
The palette balances warm organic substrates with crisp, high-density pigment:

- **Primary Accent (`#eb5e28` - Vermilion):** The singular high-chroma element. Used exclusively for progress indicators, active playback thumbs, download states, active navigation pips, and key transactional CTAs. Never used for decorative washes or large background planes.
- **Primary Ink (`#403d39` - Deep Charcoal Ink):** Replaces pure black in light mode. Delivers softer, print-grade contrast against ivory backdrops without screen glare.
- **Surface Paper (`#fffcf2` - Warm Ivory Paper):** The light canvas foundation. Simulates light novel paperbacks and creates an immediate sense of tactile warmth.
- **Structural Stone (`#ccc5b9` - Stone Grey):** Low-contrast architectural divider line, card borders, track backdrops for sliders, and inactive tab indicators.
- **Night Surface (`#252422` - Rich Pitch Dark):** The canvas base for dedicated reader sheets, nocturnal reader themes, and the immersive audiobook player viewport. In night mode, vermilion remains identical while ink and paper flip inverted roles with calibrated optical contrast.

## Typography
Typographic rhythm depends on the contrast between **Manrope**'s geometric structural elegance for titles and curated metadata headers, paired with **Inter**'s clinical neutrality for body text, lists, and playback indices.

- **Numerics & Metadata:** Chapter releases, duration timestamps, and percentages use tabular lining figures (`font-variant-numeric: tabular-nums`) to prevent horizontal jitter during real-time audiobook scrub or page flips.
- **Editorial Labels:** `label-sm` is intentionally tracked out (+0.06em) and used in all-caps for media category markers (`MANGA`, `LIGHT NOVEL`, `AUDIOBOOK`).
- **Novel Reader Overrides:** In reading viewports, Inter body scales flexibly from 15px to 22px with dynamic line-height tracking calculated at `1.6x` to `1.8x` the target font size for continuous visual comfort.

## Layout & Spacing
Built on a strict 8px baseline rhythm (with a 4px sub-grid for icons and badges), the system enforces disciplined density tailored for handheld single-thumb operation.

- **Grid Systems:**
  - **Mobile (<600px):** 4-column fluid layout with `1.25rem` (20px) margins and `1rem` (16px) gutters. Shelf carousels bleed edge-to-edge with the outer margin matching the 20px padding start.
  - **Tablet (600px–1024px):** 8-column layout with `2rem` margins, enabling split master-detail reading interfaces (table of contents pinned alongside panel view).
  - **Desktop / Foldable Expanded (>1024px):** 12-column bounded layout maxing out at 1280px with centered optical distribution.
- **Cover Artwork Aspect Ratio:** Book, comic, and audiobook sleeves standardize strictly on a `2:3` vertical ratio for print titles, while dedicated audiobook discs/overlays crop smoothly to a `1:1` container when displayed inside standalone players.

## Elevation & Depth
Depth in this system avoids heavy drop shadows, favoring tonal paper layering and hairline architectural borders:

- **Level 0 (Flat Ground):** `#fffcf2` (Light) or `#252422` (Dark). Native application canvas.
- **Level 1 (Card & Shelf Surfaces):** Pure unshifted background bordered by a 1px solid hairline (`#ccc5b9` at 40% alpha). Shadows are strictly ambient: `0 2px 8px rgba(37, 36, 34, 0.04)`.
- **Level 2 (Sticky Mini-Players & Modals):** `#fffcf2` elevated with `0 8px 24px rgba(37, 36, 34, 0.08)` and bounded by a 1px perimeter border.
- **Level 3 (Immersive Sheets / Readers):** Total backdrop veil: `#252422` at 65% blur opacity (`backdrop-filter: blur(16px)`).
- **Dark Mode Elevation:** Elevates exclusively via tint stepping: Surface `#252422`, Elevated Card `#2d2c29`, Overlay `#383632`. No shadows are used in dark mode; hairline strokes with 15% opacity white define object edges.

## Shapes
Geometry uses clean, organic curvature without veering into playful bubbled forms:

- **Covers & Cards:** Master 2:3 media items utilize `12px` (`0.75rem`) border radius, preserving the feel of bounded book corners.
- **Interactive Surfaces (Buttons, Inputs, Floating Nav):** Standardized on `14px` to `16px` (`rounded-lg`), delivering comfortable touch targets.
- **Badges & Progress Thumbs:** Utilize pill-shapes (`rounded-full`) to contrast sharply against rectilinear book sleeves.
- **Cover Inner Radius:** Embedded cover images within framed containers mimic their parent's curvature minus the container padding to eliminate corner distortion.

## Components

### Buttons
- **Primary:** Solid `#eb5e28` fill with `#fffcf2` text. Height: 48px on mobile. Font: `label-lg`. Pressed state applies a 0.98 scale transform with an active darkening filter.
- **Secondary / Ghost:** Outlined with 1px `#ccc5b9`, text in `#403d39`. Background transitions to `#ccc5b9` at 15% alpha on hover or press.
- **Icon Actions:** 44x44px minimum tap target enclosing a 22px hairline outline icon (1.5px stroke weight).

### Media Cards (2:3 Ratio)
- Standardized vertical cover art container with `12px` rounded corners.
- **Progress Overlay:** Continuous 3px linear bar anchored to the bottom edge of the artwork: background track `#403d39` (40% opacity), filled with `#eb5e28`.
- **Badge Indicator:** Top-right anchored capsule (`label-sm`), background `#252422` (85% alpha), text `#fffcf2`, displaying format tags (`EPUB`, `VOL. 12`, `128K MP3`).

### Audiobook Mini-Player
- Fixed persistent bar floating 8px above bottom navigation.
- 64px height, background `#fffcf2` (light) or `#2d2c29` (dark) with 1px top border.
- Left-aligned 44x44px cover thumbnail (`rounded-md`), centered track title and author in `label-md` and `body-sm`, right-aligned play/pause toggle and scrubber scrub pill.

### Chips & Filters
- Compact 32px height, 16px radius.
- Inactive: `#fffcf2` background, 1px `#ccc5b9` border, `#403d39` text.
- Active: `#252422` fill with `#fffcf2` text, displaying a `#eb5e28` dot indicator to signify active chapter filters or source toggles.

### Lists & Chapter Rows
- 56px minimum row height separated by 0.5px hairline `#ccc5b9` borders.
- Chapter index set in tabular `label-md`, unread chapters in bold `#403d39`, completed chapters dimmed to `#ccc5b9`.
- Download status indicated via 18px stroke icons: queued, downloaded (filled vermilion check), or streaming cloud icon.

### Form Inputs & Search
- 48px height, rounded `12px` with a subtle `#ccc5b9` outer stroke.
- Placeholder text in `#ccc5b9`. On focus, the stroke transitions to `#eb5e28` with a 0-spread 2px glow ring (`#eb5e28` at 20% alpha).