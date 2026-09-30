---
name: Vital Precision
colors:
  surface: '#fbf8ff'
  surface-dim: '#dad9e3'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f2fd'
  surface-container: '#eeedf7'
  surface-container-high: '#e8e7f1'
  surface-container-highest: '#e3e1ec'
  on-surface: '#1a1b22'
  on-surface-variant: '#5c4037'
  inverse-surface: '#2f3038'
  inverse-on-surface: '#f1effa'
  outline: '#916f65'
  outline-variant: '#e6beb2'
  surface-tint: '#ad3300'
  primary: '#a93100'
  on-primary: '#ffffff'
  primary-container: '#d34000'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb59e'
  secondary: '#0060ac'
  on-secondary: '#ffffff'
  secondary-container: '#64a8fe'
  on-secondary-container: '#003c70'
  tertiary: '#006a34'
  on-tertiary: '#ffffff'
  tertiary-container: '#008644'
  on-tertiary-container: '#f6fff3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59e'
  on-primary-fixed: '#3a0b00'
  on-primary-fixed-variant: '#842500'
  secondary-fixed: '#d4e3ff'
  secondary-fixed-dim: '#a4c9ff'
  on-secondary-fixed: '#001c39'
  on-secondary-fixed-variant: '#004883'
  tertiary-fixed: '#6dfe9c'
  tertiary-fixed-dim: '#4de082'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005227'
  background: '#fbf8ff'
  on-background: '#1a1b22'
  surface-variant: '#e3e1ec'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: '0'
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: '0'
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: '0'
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.07em
  micro-tag:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
  headline-md-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 26px
    letterSpacing: -0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The design system embodies **Vital Precision**: a health-focused aesthetic that balances clinical clarity with athletic energy. It is designed for high-performance health tracking where accessibility and rapid data scanning are paramount. 

The visual style is a fusion of **Modern Minimalism** and **High-Contrast Functionalism**. By utilizing a "Canvas and Surface" approach, the UI creates a hierarchy of information through stacking rather than complex decoration. The interface is characterized by generous whitespace, high-legibility sans-serif typography, and "2xl" soft rounded corners that humanize the precision-driven data. The emotional response should be one of confidence, calm, and motivation—feeling like a premium digital coach that is both professional and approachable.

## Colors

The palette is rooted in a high-contrast foundation to ensure maximum readability and accessibility. 

- **Primary (Kinetic Orange):** Reserved for critical actions, active states, and focus indicators. It provides the "pulse" of the application.
- **Secondary & Tertiary (Health Tones):** A calming blue and a refreshing emerald green are used exclusively for categorization (e.g., muscle groups, equipment, or health metrics). These are often applied as high-legibility text over soft, desaturated versions of the same hue.
- **Neutral Foundation:** The "Canvas" uses a cool zinc-white to reduce glare, while "Surfaces" use pure white to make interactive cards and containers pop.
- **Typography:** Deep obsidian is used for primary headings to ensure a high contrast ratio (well above WCAG AAA), while slate and zinc grays handle secondary and tertiary metadata.

## Typography

This design system uses **Inter** exclusively to leverage its exceptional legibility and systematic weight distribution. 

- **Headlines:** Utilize tight line-heights and negative letter-spacing to create a "dense" and authoritative look.
- **Body:** Features slightly increased line-height (1.5x - 1.6x) to facilitate easy reading during physical activity.
- **Labels & Tags:** Use uppercase styling with expanded letter-spacing for micro-metadata to maintain clarity at small scales. 
- **Accessibility:** Minimum font size for functional body text is capped at 14px to ensure readability for all users.

## Layout & Spacing

The system follows a **Fluid Grid** philosophy that prioritizes content density and ease of thumb-access on mobile devices.

- **Grid:** On mobile, a single or double-column fluid grid is used. On desktop, an `auto-fill` grid expands to fill the viewport, maintaining a maximum content width of 1200px.
- **Rhythm:** All spacing is derived from a 4px baseline. Components use `16px` (md) for internal padding and `24px` (lg) for section separation.
- **Touch Targets:** Interactive elements (buttons, chips, inputs) must maintain a minimum hit area of 44x44px. 
- **Safe Areas:** Adhere to mobile safe areas, ensuring sticky footers or navigation bars do not interfere with OS-level gestures.

## Elevation & Depth

Depth is communicated through **Tonal Layering** and **Ambient Shadows** to maintain a clean, modern feel.

- **Layers:** The background (`#f4f4f5`) acts as the furthest depth. Surface containers (`#ffffff`) sit on top, defined by a 1px hairline border (`#e4e4e7`).
- **Shadows:** Standard states use no shadows to keep the UI "flat" and fast. Elevation is reserved for **Hover** and **Active** states (e.g., a card lifting) using an extra-diffused, low-opacity shadow: `0 8px 24px rgba(0,0,0,0.08)`.
- **Modals:** Use a hardware-accelerated **Backdrop Blur** (6px) with a semi-transparent dark overlay (`rgba(0,0,0,0.45)`) to focus the user's attention on the primary task while maintaining context.

## Shapes

The shape language is defined by **Soft Geometricism**. 

- **Standard Radius:** 0.5rem (8px) for buttons and inputs.
- **Large Radius (2xl):** 1rem (16px) to 1.5rem (24px) for cards, modal containers, and main content wrappers. This "2xl" roundedness is a signature of the system, providing a premium, modern health-app aesthetic.
- **Pills:** Full-round (9999px) is used exclusively for status chips, category tags, and search bars to differentiate them from structural containers.

## Components

- **Buttons:** 
  - *Primary:* Solid Kinetic Orange with white text. 10px radius.
  - *Secondary:* Transparent fill, 1px `#e4e4e7` border, slate text.
- **Chips:** Pill-shaped. Active chips use a soft 8% opacity tint of the primary/secondary color with a matching 1px border.
- **Cards:** White background, 16px radius, 1px border. Use a 3:4 or 16:9 aspect ratio for health/exercise media. On hover, the border transitions to Kinetic Orange.
- **Input Fields:** Soft gray fill (`#f4f4f5`), 10px radius, 1px border. Focus state uses a 1px Kinetic Orange border.
- **Lists:** Clean dividers using 1px `#e4e4e7`. Use 16px horizontal padding.
- **Checkboxes/Radios:** Use Kinetic Orange for checked states. Ensure the hit area spans the entire row for better mobile accessibility.
- **Progress Indicators:** Use the secondary (blue) or tertiary (green) colors to indicate completion, providing a positive visual reinforcement.