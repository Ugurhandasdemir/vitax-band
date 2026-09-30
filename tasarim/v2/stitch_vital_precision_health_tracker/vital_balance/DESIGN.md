---
name: Vital Balance
colors:
  surface: '#fbf8ff'
  surface-dim: '#dad9e3'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f2fd'
  surface-container: '#eeedf7'
  surface-container-high: '#e8e7f1'
  surface-container-highest: '#e3e1eb'
  on-surface: '#1a1b22'
  on-surface-variant: '#5b4139'
  inverse-surface: '#2f3037'
  inverse-on-surface: '#f1effa'
  outline: '#8f7067'
  outline-variant: '#e3beb4'
  surface-tint: '#ad3300'
  primary: '#a83100'
  on-primary: '#ffffff'
  primary-container: '#d34000'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb59e'
  secondary: '#0060ab'
  on-secondary: '#ffffff'
  secondary-container: '#6eaeff'
  on-secondary-container: '#004076'
  tertiary: '#016a34'
  on-tertiary: '#ffffff'
  tertiary-container: '#2b844b'
  on-tertiary-container: '#f5fff2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59e'
  on-primary-fixed: '#3a0b00'
  on-primary-fixed-variant: '#842500'
  secondary-fixed: '#d3e3ff'
  secondary-fixed-dim: '#a3c9ff'
  on-secondary-fixed: '#001c39'
  on-secondary-fixed-variant: '#004883'
  tertiary-fixed: '#9df6b1'
  tertiary-fixed-dim: '#81d997'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005227'
  background: '#fbf8ff'
  on-background: '#1a1b22'
  surface-variant: '#e3e1eb'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg-medium:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-md-medium:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0em
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
  micro-tag:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
---

## Brand & Style

This design system establishes an empathetic, clinically rigorous, yet deeply warm digital wellness companion designed explicitly for compact mobile viewports (optimized baseline: iPhone SE 3, 375×667 pt). The aesthetic rejects artificial depth, skeuomorphic gloss, and heavy elevation models in favor of a crisp, flat architectural language built on generous negative space, high contrast accessibility (WCAG AAA), and rhythmic hairline borders.

The product's personality embodies:
- **Empathetic Precision**: Warm, encouraging Turkish microcopy paired with zero-ambiguity clinical metric visualization.
- **Airy Focus**: Uncluttered single-column flows that respect limited screen real estate while mitigating cognitive fatigue.
- **Vibrant Purpose**: Energetic orange driver accents balanced by serene, functional diagnostic hues (Health Blue, Emerald Green, and Alert Red) mapped directly to biological domains.

## Colors

The palette employs a crisp, purposeful chromatic architecture configured strictly for light mode readability:

- **Canvas & Surface**: The foundation sits on Cool Lavender White (`#FBF8FF`), creating an airy, clinical yet soft backdrop. Surfaces, cards, and bottom sheets use Pure White (`#FFFFFF`) to establish stark contrast, bound crisply by hairline dividers in Soft Lilac Gray (`#E3E1EC`).
- **Primary Accents**: High-velocity interaction lives in two shades: Bright Orange (`#D34000`) acts as the active fill color for primary push buttons and floating action triggers, while Kinetic Orange (`#A93100`) commands pressed states, focused rings, and critical progress milestones.
- **Diagnostic Tones**: Color encodes data categories unambiguously:
  - **Health Blue (`#0060AC`)**: Heart rate telemetry, hydration status, liquid intake, and protein metrics.
  - **Emerald Green (`#006A34`)**: Positive goals achieved, vital stability, balanced nutrition, and complex carbohydrates.
  - **Alert Red (`#BA1A1A`)**: Critical thresholds, dehydration warnings, missed medication alerts, and error states.
- **Typography & Neutrals**: Copy contrast is uncompromising. High-priority text and headers use Deep Obsidian (`#1A1B22`) reaching beyond a 12:1 contrast ratio against white. Supporting metadata, timestamps, and contextual captions leverage Warm Umber (`#5C4037`), delivering gentler hierarchy without sacrificing outdoor legibility.

## Typography

The type system is built on a single, battle-tested typeface: **Inter**. By standardizing on one versatile neo-grotesque, visual clutter is eliminated and Turkish diacritics (ç, ğ, ı, ö, ş, ü, İ) render with optical stability across dense clinical layouts.

- **Scale Floor**: The smallest running body type is strictly bounded at 14px (`body-md`) to guarantee readability for older demographics and glanceability during physical activities.
- **Editorial Hierarchy**: 
  - `display-lg` (32/800) is reserved for daily score summaries and primary greeting anchors.
  - `headline-lg` (22/700) and `headline-md` (18/700) section content into digestable cards.
  - `label-caps` (11/700 uppercase with wide `+0.08em` tracking) provides crisp metadata categories (e.g., "GÜNLÜK ÖZET", "NABIZ", "HİDRASYON").
  - `micro-tag` (10/700) powers tiny inline status badges and compact chart axis indicators.
- **Copy Tone**: Turkish language strings prioritize conversational, warm phrasing over cold medical jargon (e.g., "Harika gidiyorsun!", "Bugünkü su hedefin tamamlandı", "Nabzın dinlenme modunda").

## Layout & Spacing

Designed specifically for 375pt-wide screens, the spatial rhythm enforces breathing room without pushing critical content below the fold.

- **Grid Architecture**: A 4-column fluid layout with `12px` (0.75rem) gutters and `16px` (1rem) safe-edge canvas margins ensures full-width modules remain within thumb reach.
- **Vertical Rhythm**:
  - `space-xs` (4px): Micro-gaps between related badge text, status dots, and inline units.
  - `space-sm` (8px): Internal paddings for compact chips, list item item-to-label gaps.
  - `space-md` (16px): Standard inner card padding and standard vertical component separation.
  - `space-lg` (20px): Structural grouping distance between discrete health parameter sections.
  - `space-xl` (24px): Primary segment divisions and bottom-sheet header clearances.
- **View-Aware Ergonomics**: All interactive tap targets enforce an absolute minimum dimension of 44×44pt, keeping the floating CTA anchored in the lower thumb zone with a 16px offset from the iOS home indicator.

## Elevation & Depth

This system intentionally eliminates drop shadows, ambient blur filters, and multi-stop gradients. Depth is expressed purely through structural stacking and planar contrast:

- **Flat Border Enclosure**: Cards and panels sit flat on the Cool Lavender White (`#FBF8FF`) canvas. Visual grouping is achieved via a pure white fill (`#FFFFFF`) framed by a crisp 1px hairline border rendered in Soft Lilac Gray (`#E3E1EC`).
- **Interactive Planes**: Modals, alert overlays, and sliding bottom sheets employ the same pure white fill with high-contrast outlines and a 20% darkened neutral backdrop scrim (`#1A1B22` at 0.20 opacity), avoiding decorative blur effects.
- **State Feedback**: States are communicated through bold color shifts (such as a 1.5px `#A93100` outline on focus or active inputs) rather than elevated shadow offsets.

## Shapes

The shape system balances crisp utilitarian forms with organic touch surfaces:

- **Cards & Health Containers**: Large interactive panels and data cards feature soft corners scaled at `16px` to `24px` radius. This softens the high-contrast aesthetic while keeping data grids neatly aligned.
- **Interactive Controls (Buttons & Inputs)**: All text inputs, selection bars, primary action buttons, and numeric input fields adhere to a uniform `10px` radius, giving interactive controls an unmistakable tactile identity distinct from cards.
- **Pills (Chips, Badges, Search & Floating Controls)**: Secondary filter tags, micro-badges, search fields, segmented tabs, and circular floating triggers use full-pill curvature (`9999px`), inviting immediate contact and making status tags feel friendly and modular.

## Components

### Buttons
- **Primary Button**: 48px height, 10px corner radius. Filled with Bright Orange (`#D34000`), white label in `label-md`. Pressed state shifts immediately to Kinetic Orange (`#A93100`). Zero shadow.
- **Secondary Action**: 48px height, 10px corner radius. Pure White surface (`#FFFFFF`) with 1px Soft Lilac Gray (`#E3E1EC`) border and Deep Obsidian (`#1A1B22`) label. Active/focus transitions border to `#A93100`.
- **Floating Action Button (Hızlı Ekle)**: 56px circular pill. Filled with Bright Orange (`#D34000`) with white iconography. Positioned fixed at bottom-right, 16px margins.

### Cards & Metric Displays
- **Vital Metric Card**: Pure White (`#FFFFFF`) surface, 16px or 20px radius, 1px Soft Lilac Gray (`#E3E1EC`) border, 16px internal padding.
- **Structure**: Uppercase `label-caps` in Warm Umber (`#5C4037`) at the top, bold metric value in `display-lg` or `headline-lg` in Deep Obsidian (`#1A1B22`), paired with a mini progress tracker or spark-bar tinted in the metric's functional color (Health Blue, Emerald Green, or Alert Red).

### Chips & Filter Pills
- Fully pill-shaped (`9999px`), 32px height, 12px horizontal padding.
- **Inactive**: Pure White background, 1px `#E3E1EC` border, Warm Umber text (`#5C4037`) in `label-md`.
- **Active**: Filled with Cool Lavender White (`#FBF8FF`), 1.5px Kinetic Orange (`#A93100`) border, Deep Obsidian text (`#1A1B22`) with bold weight.

### Input Fields
- Height 48px, 10px radius, Pure White background (`#FFFFFF`), 1px `#E3E1EC` border.
- Text: 16px `body-lg` Deep Obsidian (`#1A1B22`) to prevent iOS zoom-on-focus.
- Placeholder: Warm Umber (`#5C4037`) at 60% opacity.
- Focused state: 1.5px border in Kinetic Orange (`#A93100`).
- Error state: 1.5px border in Alert Red (`#BA1A1A`) with a supporting error text line in 14px Warm Umber below the field.

### Selection Controls (Checkboxes & Radios)
- **Checkboxes**: 22×22px square with 6px rounded corners. Inactive has 1.5px border in `#E3E1EC`. Active is filled with Bright Orange (`#D34000`) with a white 2px checkmark.
- **Radio Buttons**: 22×22px circle. Active displays a 6px centered dot in Bright Orange (`#D34000`) surrounded by an active border.

### Status Banners & Modals
- Inline notification cards feature a 4px solid left-side indicator stripe colored by state: Alert Red (`#BA1A1A`) for warnings, Emerald Green (`#006A34`) for success milestones, and Health Blue (`#0060AC`) for routine hydration/logging nudges.
- Pure White card background with 16px border radius, keeping message delivery friendly, direct, and unencumbered.