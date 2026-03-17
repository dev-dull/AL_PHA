# AlPHA — Product Designer Implementation Plan

## Senior Product Designer Onboarding & Design Specification

---

## 1. Role & Responsibilities

### What Design Owns

**UI/UX Specification**
- All screen layouts, flows, and state definitions across phone, tablet, and web breakpoints
- Interaction design for every user gesture (tap, long-press, swipe, drag, pinch, keyboard, hover, right-click)
- Information architecture: navigation hierarchy, screen transitions, content prioritization
- Empty states, error states, loading states, and edge cases for every screen

**Visual Language & Design System**
- Complete design token set (colors, typography, spacing, elevation, radii, motion curves)
- Reusable component library with all interactive states
- Marker symbol design — the visual identity of the app
- Light and dark mode specifications
- App icon and store listing assets

**Accessibility**
- WCAG 2.1 AA compliance specifications
- Contrast ratio validation for all marker colors on all background variants
- Screen reader annotation for every interactive element
- Touch target sizing enforcement (minimum 44x44 logical pixels)
- Reduced motion alternatives for all animations

**Design QA**
- Visual regression checklists for each sprint delivery
- Pixel-level review of implemented screens against specs
- Cross-platform visual consistency audits (Android, iOS, Chrome, Safari, Firefox)

### What Design Hands Off to Engineering

| Deliverable | Format | Cadence |
|---|---|---|
| Design tokens | JSON export from Figma (via Tokens Studio) mapped to `lib/design_system/theme/` | Once, then updated as needed |
| Screen specs | Figma frames with auto-layout, redlines, and dev-mode annotations | 1-2 sprints ahead of eng |
| Interaction specs | Annotated prototypes + written timing/easing specs | Alongside screen specs |
| Component specs | Figma component with all variants, states, and slot documentation | Before the component is coded |
| Asset exports | SVGs for icons, PNGs at 1x/2x/3x for raster assets | On demand |
| Accessibility annotations | Layer annotations in Figma with semantic labels, roles, and focus order | With each screen spec |

### What Design Validates with QA

- Visual accuracy: does the implementation match the Figma spec within 2px tolerance?
- Animation timing: do transitions match specified durations and curves?
- State coverage: are all defined states (empty, loading, populated, error, disabled) implemented?
- Responsive behavior: does the layout shift correctly at 600px and 1024px breakpoints?
- Dark mode: are all surfaces, text, and marker colors correct in dark theme?
- Accessibility: do screen readers announce the correct labels? Are focus rings visible? Do touch targets meet 44x44 minimums?

---

## 2. Design Tools & Deliverables

### Figma File Structure

```
AlPHA Design System (Library File)
├── Cover Page
├── Foundations
│   ├── Colors (Light + Dark palettes, marker colors, semantic colors)
│   ├── Typography (scale, weights, line heights)
│   ├── Spacing (4px base grid tokens)
│   ├── Elevation (shadow definitions)
│   ├── Radii (corner radius scale)
│   └── Motion (duration + easing curve reference)
├── Components
│   ├── MarkerIcon (6 symbols x 3 states x 2 themes)
│   ├── GridCell (empty, filled, hover, focused, disabled)
│   ├── TaskRow (normal, dragging, completed, cancelled, hover)
│   ├── ColumnHeader (default, active-context, today-highlight)
│   ├── BoardCard (default, archived, progress ring variants)
│   ├── Buttons (primary, secondary, text, icon, FAB)
│   ├── Inputs (text field, search bar, dropdown)
│   ├── Chips (filter chip, template type badge)
│   ├── Dialogs (confirmation, destructive, form)
│   ├── Bottom Sheets (task detail, marker picker, quick-add)
│   ├── Snackbars (undo, success, error)
│   ├── Navigation (bottom nav bar, side rail, side drawer)
│   └── Skeletons (board list loading, grid loading)
└── Iconography
    ├── Marker Symbols (SVG masters at 44px, 24px, 16px)
    ├── Tab Bar Icons
    └── App Icon

AlPHA Screens (Product File)
├── Cover Page + Flow Map
├── Onboarding
├── Board List (Home)
├── Board Matrix (Core)
├── Task Detail
├── Create/Edit Board
├── Template Picker
├── Migration Wizard
├── Settings
├── Error & Empty States
└── Platform Variants
    ├── Phone (< 600px)
    ├── Tablet (600-1024px)
    └── Web/Desktop (> 1024px)

AlPHA Prototypes (Prototype File)
├── Onboarding Flow
├── Marker Tap Cycling
├── Long-Press Marker Picker
├── Swipe-to-Complete
├── Drag-to-Reorder
├── Migration Wizard Flow
└── Board Creation Flow
```

### Prototype Tools

- **Figma Prototyping** for click-through flows and screen transitions
- **Principle or Rive** for complex micro-interactions (marker cycle animation, strikethrough sweep) — exported as Lottie/Rive files for direct Flutter consumption
- **Figma Smart Animate** for demonstrating drag-to-reorder and swipe gesture feedback to stakeholders

### Handoff Format

- **Design Tokens**: Exported via Tokens Studio for Figma as a JSON file. Engineering maps these to `AppColors`, `AppTypography`, and spacing constants in `lib/design_system/theme/`.
- **Specs & Redlines**: Figma Dev Mode enabled on all frames. Engineers inspect padding, sizing, color values, and font properties directly.
- **Assets**: Marker symbols exported as SVGs and placed in `assets/images/`. App icon exported per platform guidelines (Android adaptive icon layers, iOS 1024x1024).
- **Animation Specs**: Written document per animation with duration (ms), easing curve (Cubic Bezier values mapped to Flutter `Curves.*`), and property changes (scale, opacity, translation).

---

## 3. Design Sprint Schedule (12 Weeks)

Design runs 1-2 sprints ahead of engineering per the plan's phased delivery.

### Sprint 1 (Week 1-2): Foundations + Board List

**Aligns with Engineering Phase 0 (Foundation)**

| Deliverable | Detail |
|---|---|
| Design tokens (complete) | Full color palette, typography scale, spacing scale, elevation, radii, motion curves — light and dark |
| Component library (batch 1) | MarkerIcon (all 6 symbols, all states), GridCell, AlphaCard, AlphaButton, FAB |
| Board List screen (wireframe + high-fidelity) | All 3 breakpoints, all states (empty, populated, archived toggle) |
| ResponsiveScaffold spec | Bottom nav (phone), rail nav (tablet), side drawer (desktop) |
| App icon design | Concept exploration and final direction |

**Review milestone**: End of Week 2 — Design review with engineering lead to validate token structure maps cleanly to Flutter `ThemeData`.

### Sprint 2 (Week 3-4): Board Matrix — The Core Screen

**Design stays ahead of Engineering Phase 1 (Core Grid, Week 3-5)**

| Deliverable | Detail |
|---|---|
| Board Matrix wireframes | Frozen task column + scrollable grid, all breakpoints |
| Board Matrix high-fidelity | Light and dark, populated with realistic data (7-col weekly, 31-col monthly) |
| MarkerCell interaction spec | Tap cycle animation (timing, scale bounce, color transition), long-press picker |
| Swipe-to-complete spec | Threshold (40% of row width), visual feedback (green sweep right, red sweep left), undo snackbar |
| Drag-to-reorder spec | Pickup elevation change, placeholder gap, auto-scroll at edges |
| Column header design | Default, today-highlight (time mode), active-context (context mode) |

**Review milestone**: End of Week 3 — Interactive prototype walkthrough with full team. This is the make-or-break screen. Expect 2-3 iteration cycles.

### Sprint 3 (Week 5-6): Task Detail + Board Creation + Column Management

**Continues ahead of Engineering Phase 1 completion**

| Deliverable | Detail |
|---|---|
| Task Detail screen | Bottom sheet (phone) vs side panel (tablet/desktop), form fields, marker summary grid |
| Create/Edit Board screen | Name input, type picker (segmented control), column editor with drag-to-reorder |
| Column management | Add/rename/delete column inline in the matrix header area |
| Quick-add task bottom sheet | Minimal: text field + submit. Phone-only; on desktop, inline row appears in grid |
| Component library (batch 2) | Inputs, chips, dialogs, bottom sheets, snackbars |

**Review milestone**: End of Week 6 — Design-engineering sync to validate Task Detail implementation matches spec.

### Sprint 4 (Week 7-8): Templates + Migration Wizard

**Aligns with Engineering Phase 2 (Templates & Migration, Week 6-7)**

| Deliverable | Detail |
|---|---|
| Template Picker screen | Gallery grid layout, template preview card (showing miniaturized column layout), selection confirmation |
| Migration Wizard flow | 4-step flow: trigger banner, target board selection, task checklist, confirmation summary |
| Migration progress indicators | Migrated marker (`>`) visual treatment, source board visual dimming |
| Board archiving UX | Archive action in overflow menu, archived board visual treatment (dimmed card, "Archived" badge), toggle in board list |

**Review milestone**: End of Week 7 — Stakeholder review of migration flow prototype.

### Sprint 5 (Week 9-10): Onboarding + Polish + Platform Optimization

**Aligns with Engineering Phase 3 (Polish, Week 8-9)**

| Deliverable | Detail |
|---|---|
| Onboarding carousel | 4 screens: (1) Welcome/value prop, (2) Interactive mini-grid demo, (3) Marker system explanation, (4) Template selection to create first board |
| Dark mode audit | Review every screen in dark mode, adjust any contrast issues |
| Loading skeletons | Shimmer placeholders for board list cards and grid cells |
| Empty state illustrations | Empty board list ("Create your first board"), empty board ("Add your first task") |
| Web-specific specs | Hover states for all interactive elements, right-click context menu design, cursor changes, keyboard focus rings |
| Mobile-specific specs | Haptic feedback mapping, pinch-to-zoom behavior documentation, edge gesture conflict avoidance |

**Review milestone**: End of Week 9 — Full app walkthrough in all three breakpoints, both themes.

### Sprint 6 (Week 11-12): Settings + Sync UI + Final QA

**Aligns with Engineering Phase 4 (Sync & Auth, Week 10-12)**

| Deliverable | Detail |
|---|---|
| Settings screen | Theme picker (system/light/dark), default columns configuration, account section (sign in/out/delete) |
| Sync status indicator | Subtle icon in app bar: synced (check), syncing (spinner), offline (cloud-off), error (warning) |
| Auth screens (if needed) | Sign in, sign up, forgot password — or defer to hosted Cognito UI |
| Final design QA pass | Review all implemented screens against specs, file defect tickets with screenshots |
| Design system documentation | Written usage guidelines for each component |

**Review milestone**: End of Week 12 — Final design sign-off before v1.0 release.

---

## 4. Design System Specification

### 4a. Color Palette

#### Marker Colors

| Marker | Symbol | Light Mode | Dark Mode | Usage |
|---|---|---|---|---|
| DOT (To Do) | `*` | `#4A90D9` (Blue 500) | `#6AABF0` (Blue 300) | Scheduled/assigned to column |
| CIRCLE (Started) | `O` | `#F5A623` (Orange 500) | `#FFB94D` (Orange 300) | Work begun, not finished |
| X (Done) | `X` | `#7ED321` (Green 500) | `#9AE649` (Green 300) | Completed in this column |
| STAR (Deadline) | `*` | `#D0021B` (Red 600) | `#FF4D4D` (Red 400) | Hard deadline / high priority |
| TILDE (Recurring) | `~` | `#9013FE` (Purple 500) | `#B266FF` (Purple 300) | Recurring task marker |
| MIGRATED | `>` | `#8B8B8B` (Gray 500) | `#ABABAB` (Gray 400) | Task moved to next period |

All dark-mode marker variants are lightened to maintain a minimum 4.5:1 contrast ratio against the dark surface color.

#### Semantic Colors

| Token | Light | Dark | Usage |
|---|---|---|---|
| `surface.primary` | `#FFFFFF` | `#121212` | Main background |
| `surface.secondary` | `#F5F5F5` | `#1E1E1E` | Card backgrounds, headers |
| `surface.tertiary` | `#FAFAFA` | `#2A2A2A` | Zebra-striped alternate rows |
| `text.primary` | `#212121` (Gray 900) | `#E0E0E0` (Gray 300) | Primary text |
| `text.secondary` | `#757575` (Gray 600) | `#9E9E9E` (Gray 500) | Secondary/caption text |
| `text.disabled` | `#BDBDBD` (Gray 400) | `#616161` (Gray 700) | Disabled text |
| `border.default` | `#E0E0E0` | `#333333` | Grid lines, dividers |
| `border.focus` | `#4A90D9` | `#6AABF0` | Focus rings (keyboard nav) |
| `action.primary` | `#4A90D9` | `#6AABF0` | Primary buttons, links |
| `action.destructive` | `#D0021B` | `#FF4D4D` | Delete, cancel actions |
| `feedback.success` | `#7ED321` | `#9AE649` | Success snackbars |
| `feedback.warning` | `#F5A623` | `#FFB94D` | Warning banners |
| `feedback.error` | `#D0021B` | `#FF4D4D` | Error messages |
| `swipe.complete` | `#7ED321` at 20% opacity | `#9AE649` at 15% opacity | Swipe-right background |
| `swipe.cancel` | `#D0021B` at 20% opacity | `#FF4D4D` at 15% opacity | Swipe-left background |

#### Grid-Specific Colors

| Token | Light | Dark |
|---|---|---|
| `grid.line` | `#E0E0E0` | `#333333` |
| `grid.headerBg` | `#F5F5F5` | `#1E1E1E` |
| `grid.taskColumnBg` | `#FFFFFF` | `#181818` |
| `grid.cellHover` | `#F0F0F0` | `#2A2A2A` |
| `grid.cellFocus` | `#E3F2FD` | `#1A3A5C` |
| `grid.todayColumn` | `#E3F2FD` at 50% opacity | `#1A3A5C` at 30% opacity |

### 4b. Typography

**Font Family**: Inter (primary), with system font fallback stack. Inter is chosen for its excellent legibility at small sizes (critical for grid cells), its open-source license, and its comprehensive weight range.

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|---|---|---|---|---|---|
| `heading.xl` | 28px | 700 (Bold) | 36px | -0.5px | Onboarding titles |
| `heading.lg` | 22px | 600 (SemiBold) | 28px | -0.3px | Screen titles |
| `heading.md` | 18px | 600 (SemiBold) | 24px | 0 | Board names, section headers |
| `body.lg` | 16px | 400 (Regular) | 24px | 0 | Task titles in detail view |
| `body.md` | 14px | 400 (Regular) | 20px | 0 | Task titles in grid row |
| `body.sm` | 12px | 400 (Regular) | 16px | 0.1px | Descriptions, secondary info |
| `caption` | 11px | 500 (Medium) | 14px | 0.2px | Column headers, timestamps |
| `grid.cell` | 16px | 600 (SemiBold) | 16px | 0 | Marker symbols inside cells |
| `label` | 12px | 500 (Medium) | 16px | 0.5px | Buttons, chips, badges |
| `overline` | 10px | 500 (Medium) | 14px | 1.0px | Board type badge, ALL CAPS |

### 4c. Spacing & Layout

**Base unit**: 4px. All spacing values are multiples of 4.

| Token | Value | Usage |
|---|---|---|
| `space.xxs` | 2px | Icon-to-text gap (tight) |
| `space.xs` | 4px | Inner padding of compact elements |
| `space.sm` | 8px | Between related elements |
| `space.md` | 12px | Component internal padding |
| `space.lg` | 16px | Section gaps, card padding |
| `space.xl` | 24px | Between sections |
| `space.xxl` | 32px | Screen-edge padding (desktop) |
| `space.xxxl` | 48px | Large vertical separations |

**Grid Cell Sizing**

| Dimension | Phone | Tablet | Desktop |
|---|---|---|---|
| Cell width | 44px (minimum) | 52px | 60px |
| Cell height | 44px (minimum) | 48px | 48px |
| Task column width | 160px-200px (flexible) | 200px-280px | 280px-360px |
| Column header height | 40px | 44px | 44px |

**Responsive Breakpoints**

| Breakpoint | Width | Layout Changes |
|---|---|---|
| Phone | < 600px | Bottom nav, full-screen sheets, FAB, compact grid cells |
| Tablet | 600-1024px | Rail nav, master-detail possible, medium grid cells |
| Desktop | > 1024px | Side drawer nav, dialogs instead of sheets, wide grid cells, hover states, keyboard nav |

**Corner Radii**

| Token | Value | Usage |
|---|---|---|
| `radius.xs` | 4px | Chips, badges |
| `radius.sm` | 8px | Cards, inputs |
| `radius.md` | 12px | Dialogs, bottom sheets |
| `radius.lg` | 16px | Board cards on home screen |
| `radius.full` | 999px | FAB, circular buttons, marker dots |

### 4d. Component Library

#### MarkerIcon

The central visual element. Six symbols, each rendered as a vector shape within a consistent bounding box.

| Symbol | Visual | Size Variants | States |
|---|---|---|---|
| DOT | Filled circle, 40% of cell width | 16px, 24px, 44px | default, hover (110% scale), pressed (90% scale + ripple) |
| CIRCLE | Stroke-only circle, 2px stroke | 16px, 24px, 44px | default, hover, pressed |
| X | Two crossed lines, 2px stroke, rounded caps | 16px, 24px, 44px | default, hover, pressed |
| STAR | Five-pointed star, filled | 16px, 24px, 44px | default, hover, pressed |
| TILDE | Sine wave, 2px stroke | 16px, 24px, 44px | default, hover, pressed |
| MIGRATED | Right-pointing chevron/arrow | 16px, 24px, 44px | default only (no interaction) |

#### GridCell

- **Size**: Minimum 44x44 logical pixels (accessibility requirement)
- **Border**: 1px `grid.line` color on right and bottom edges
- **States**: empty (transparent), filled (marker centered), hover (background tint), focused (2px `border.focus` inset ring), disabled (30% opacity overlay)
- **Tap target**: Entire cell area, no dead zones

#### TaskRow

- **Layout**: Task title left-aligned with `space.md` padding, vertically centered in row
- **States**:
  - Normal: `text.primary` color, `surface.primary` background
  - Hover (web): `grid.cellHover` background
  - Dragging: Elevated (shadow depth 4), slight scale (102%), reduced opacity on original position placeholder
  - Completed: `text.secondary` color, horizontal line through text (animated), `surface.tertiary` background
  - Cancelled: Same as completed but with `text.disabled` color
- **Swipe affordance**: Subtle chevron hints at rest (optional, can be discovered through onboarding)

#### ColumnHeader

- **Layout**: Label text centered, `caption` typography, `grid.headerBg` background
- **States**:
  - Default: Standard header styling
  - Today (time mode): `grid.todayColumn` background tint, `action.primary` text color, bold weight
  - Active context: Bottom border accent in `action.primary` color

#### BoardCard (Home Screen)

- **Layout**: Card with `radius.lg` corners, `space.lg` padding
- **Content**: Board name (`heading.md`), type badge (chip), date range (caption), progress ring (percentage of completed tasks)
- **States**: Default, pressed (scale to 98%), archived (dimmed at 60% opacity, "Archived" badge overlay)
- **Progress ring**: Circular progress indicator, stroke width 3px, colored by completion percentage (green > 75%, orange 25-75%, red < 25%)

#### Buttons

| Variant | Background | Text | Border | Min Height |
|---|---|---|---|---|
| Primary | `action.primary` | White | None | 44px |
| Secondary | Transparent | `action.primary` | 1px `action.primary` | 44px |
| Text | Transparent | `action.primary` | None | 36px |
| Destructive | `action.destructive` | White | None | 44px |
| Icon | Transparent | `text.secondary` | None | 44px (44x44) |
| FAB | `action.primary` | White | None | 56px (56x56) |

#### Other Components

- **Inputs**: 44px height, `radius.sm` corners, 1px border, focus state with `border.focus` color
- **Chips**: `radius.xs` corners, `space.xs` vertical + `space.sm` horizontal padding, `label` typography
- **Dialogs**: `radius.md` corners, max width 560px, title + body + action row layout
- **Bottom Sheets**: `radius.md` top corners, drag handle indicator (40px wide, 4px tall, centered, `border.default` color)
- **Snackbars**: Full-width on phone, max 560px on desktop, `radius.sm` corners, 4-second auto-dismiss, optional action button

### 4e. Iconography

#### Marker Symbols

Designed as vector paths (not font glyphs) for precise rendering control.

- **Master artwork**: Created at 44px in a 48px bounding box (2px optical margin)
- **Export sizes**: 16px (inline text references), 24px (compact views, summary chips), 44px (grid cells, picker)
- **Legibility requirement**: Each symbol must be unambiguously distinguishable from all others at 16px. The DOT vs CIRCLE distinction is critical — DOT is a fully filled circle, CIRCLE is stroke-only with visible interior.
- **Color is supplementary**: Symbols must remain distinguishable in monochrome (for accessibility). Color reinforces but does not replace shape differentiation.

#### App Icon

- Concept: A stylized grid/matrix motif with a prominent marker symbol (likely the DOT) in brand blue
- Exports: Android adaptive icon (foreground layer 108x108dp, background layer), iOS 1024x1024, Web favicon 32x32 and 192x192

#### Tab Bar Icons

- Board list: Grid/matrix icon (3x3 grid)
- Templates: Layout/template icon (stacked cards)
- Settings: Gear icon
- Style: 24px, 2px stroke, rounded joins, matching Material Symbols Rounded aesthetic

### 4f. Motion & Animation

**Global timing conventions:**

| Category | Duration | Curve |
|---|---|---|
| Micro-interaction (tap feedback) | 100-150ms | `Curves.easeOut` |
| State transition (marker change) | 200ms | `Curves.easeInOut` |
| Screen transition | 300ms | `Curves.easeInOutCubic` |
| Complex animation (migration) | 400-500ms | `Curves.easeInOutCubic` |
| Dismiss/remove | 200ms | `Curves.easeIn` |

**Specific Animations:**

| Animation | Spec |
|---|---|
| Marker cycle (tap) | Scale bounce: 100% -> 130% -> 100% over 200ms. Old symbol fades out (100ms), new symbol fades in (100ms), overlapping by 50ms. Color crossfades simultaneously. |
| Strikethrough (complete) | Horizontal line draws from left to right across the task title over 300ms, `Curves.easeOut`. Text color fades to `text.secondary` over the same duration. |
| Drag pickup | Scale to 102%, elevation shadow animates from 0 to 4 over 150ms. Source position shows a dashed-border placeholder. |
| Drag drop | Scale from 102% to 100%, shadow 4 to 0, over 200ms with slight bounce (`Curves.elasticOut`). |
| Page transitions | Shared-axis forward/backward (Material motion pattern). Board list to board detail: horizontal shared axis. |
| Loading skeleton | Shimmer gradient sweep from left to right, 1.5s duration, infinite repeat, `Curves.linear`. |
| Snackbar entry | Slide up from bottom + fade in, 200ms, `Curves.easeOut`. |
| Bottom sheet | Slide up from bottom, 300ms, `Curves.easeOutCubic`. Dismiss: slide down, 200ms, `Curves.easeIn`. |
| Migration marker (`>`) | Arrow slides in from left, 300ms, with a slight overshoot (`Curves.easeOutBack`). |

### 4g. Dark Mode

**Philosophy**: True dark (not just inverted). Surfaces use near-black (`#121212`) with elevated surfaces getting progressively lighter to communicate depth, per Material Design 3 dark theme guidance.

**Surface Elevation Tinting (Dark Mode Only)**:

| Elevation | Surface Tint | Usage |
|---|---|---|
| 0dp | `#121212` | Page background |
| 1dp | `#1E1E1E` | Cards, headers |
| 2dp | `#232323` | Raised cards (hover state) |
| 3dp | `#282828` | Dialogs |
| 4dp | `#2C2C2C` | Dragged elements |

**Marker Color Adjustments**: All marker colors are shifted toward lighter/more saturated variants in dark mode (specified in Section 4a) to maintain minimum 4.5:1 contrast against `#1E1E1E` card backgrounds.

**Grid-Specific Dark Mode Adjustments**:
- Grid lines use `#333333` (subtle but visible)
- Today-column highlight uses a deep blue tint (`#1A3A5C` at 30% opacity) instead of light blue
- Zebra striping uses `#2A2A2A` for alternate rows
- Completed task strikethrough line color: `#9E9E9E`

---

## 5. Screen-by-Screen Design Spec

### 5a. Board List (Home)

**Layout**: Vertical scrollable list of `BoardCard` widgets. On phone: single column. On tablet: 2-column grid. On desktop: 3-column grid with max content width of 1200px.

**Elements**:
- **App bar**: "AlPHA" logo/wordmark left-aligned, overflow menu (right) with "Show Archived" toggle
- **Board cards**: Name, type badge, date range, progress ring, last-modified timestamp
- **FAB**: Bottom-right, "+" icon, creates new board (opens template picker or blank board creator)
- **Archived toggle**: When active, archived boards appear below active boards with dimmed styling and an "Archived" section header

**States**:
- **Empty (first-time user)**: Illustration of a sample grid, headline "Create your first board", subtext "Start with a template or build your own", primary button "Get Started" (opens template picker)
- **Loading**: 3 skeleton cards with shimmer animation
- **Populated**: Cards sorted by last-modified (most recent first)
- **Error**: Error illustration, "Couldn't load boards" message, "Retry" button

**Interactions**:
- Tap card: Navigate to Board Matrix
- Long-press card: Context menu (Edit, Archive/Unarchive, Delete with confirmation)
- Pull-to-refresh (mobile): Triggers sync
- Right-click card (web): Same context menu as long-press

### 5b. Board Matrix (Core Screen)

This is the defining screen of the app and requires the most detailed specification.

**Structure** (referencing the widget tree in `plan-flutter-app.md` Section 3.2):

```
┌─────────────────────────────────────────────────┐
│ BoardToolbar                                     │
│ [< Back] [Board Name]        [Filter] [⋮ More]  │
├──────────┬──────────────────────────────────────┤
│          │  Col A  │  Col B  │  Col C  │  ...   │ <- Column headers
│          │         │ (today) │         │        │    (horizontally scrollable)
├──────────┼─────────┼─────────┼─────────┼────────┤
│ Task 1   │    •    │         │    ○    │        │
│ Task 2   │         │    •    │         │   ×    │
│ Task 3   │    ★    │    •    │    •    │        │
│ Task 4   │         │    ~    │    ~    │   ~    │
│ ——Task5——│         │         │    ×    │        │ <- completed (strikethrough)
│ ...      │         │         │         │        │
├──────────┴─────────┴─────────┴─────────┴────────┤
│                                          [+ FAB] │
└─────────────────────────────────────────────────┘
```

**Frozen Task Column**:
- Width: 160-200px on phone, 200-280px on tablet, 280-360px on desktop
- Background: `grid.taskColumnBg` (slightly differentiated from grid area)
- Task titles truncated with ellipsis if exceeding column width
- Swipe gesture zone: entire task row label area
- Reorder handle: Drag handle icon on the left edge (visible on long-press/hover on web)
- Divider: 2px right border in `grid.line` color to visually separate from scrollable area

**Scrollable Marker Grid**:
- Horizontally scrollable, vertically synced with task column via `LinkedScrollControllerGroup`
- Column headers: Sticky at top, scroll horizontally with grid
- Scroll indicator: Horizontal scrollbar on web; fade gradient hint on mobile edges to indicate more content

**Column Headers**:
- Today column (in time-mode boards): Highlighted with `grid.todayColumn` background and `action.primary` text
- Tap on header: Opens column options (rename, reorder, delete, change color)

**Tap Targets**: Every `GridCell` is minimum 44x44 logical pixels. On phone with dense monthly boards (31 columns), `InteractiveViewer` allows pinch-to-zoom so that when zoomed out, cells may appear smaller than 44px visually but the tap target detection radius is maintained at 44px equivalent.

**Zoom Behavior** (mobile only):
- `InteractiveViewer` wraps the entire grid (frozen column + scrollable area)
- `minScale: 0.5` (half-size — for overview of large boards)
- `maxScale: 2.5` (zoomed in for precise tapping)
- Default scale: 1.0 on phone, adjusts to fit visible columns on tablet
- Double-tap to toggle between fit-to-width and 1.0 scale

**Horizontal Scroll Indicators**:
- Mobile: Subtle gradient fade on the right edge when more columns are available. Fades out when scrolled to end.
- Web: Standard scrollbar, positioned below column headers

**Board Toolbar**:
- Back arrow (navigates to board list)
- Board name (tappable to edit inline)
- Filter button (future: filter by task state, priority)
- Overflow menu: Edit Board, Migration Wizard, Archive Board, Delete Board

**States**:
- **Empty board**: Grid header visible, body area shows "Add your first task" message with arrow pointing to FAB
- **Loading**: Skeleton grid with shimmer (correct number of columns based on board type)
- **Populated**: Full matrix with data
- **Error**: Error message with retry in the content area, toolbar still functional

### 5c. Task Detail

**Platform behavior**:
- Phone: Modal bottom sheet (70% screen height, draggable to full-screen)
- Tablet: Side panel (right-side, 360px wide)
- Desktop: Side panel (right-side, 400px wide) or dialog (if accessed from context menu)

**Content**:
- Task title (editable text field, `body.lg` typography)
- Description (multi-line text field, `body.md`)
- Priority picker (segmented control: None / Low / Medium / High / Deadline)
- Deadline date picker (if priority = Deadline)
- Recurrence toggle + rule editor
- Marker summary: Mini-grid showing this task's markers across all columns (read-only visual summary)
- Created/modified timestamps (`caption` typography)
- Delete button (bottom, destructive style)

**States**:
- View mode (read-only appearance, tap to edit)
- Edit mode (fields become editable, Save/Cancel buttons appear)
- New task (all fields empty, auto-focus on title, Save button creates task)

### 5d. Migration Wizard

**Multi-step flow** (4 steps):

**Step 1 — Trigger**: Banner at top of Board Matrix when period has elapsed. "This period has ended. Review and migrate incomplete tasks?" with "Start Migration" button.

**Step 2 — Target Selection**: Full-screen step.
- Header: "Where should tasks go?"
- Options: List of existing boards (filtered to matching type) + "Create New Board" option
- Create-new opens inline board creation (name + template selection)
- Progress indicator: Step dots (1 of 4)

**Step 3 — Task Selection**: Checklist of tasks with state OPEN or IN_PROGRESS.
- All pre-selected by default
- Each row shows: checkbox, task title, current marker summary
- "Select All" / "Deselect All" toggles
- Count indicator: "N of M tasks selected"

**Step 4 — Confirmation**: Summary screen.
- "N tasks will be migrated to [Board Name]"
- "M tasks will remain (completed/cancelled)"
- "Confirm" primary button, "Go Back" text button
- On confirm: animated transition showing `>` markers appearing on migrated tasks

**Responsive**: On phone, each step is full-screen with forward/back navigation. On tablet/desktop, steps can be shown in a wide dialog (600px) with sidebar step indicator.

### 5e. Template Picker

**Layout**: Gallery grid of template cards.
- Phone: 1 column, full-width cards
- Tablet: 2 columns
- Desktop: 3 columns, max width 900px

**Template Card**:
- Template name (`heading.md`)
- Type badge (chip: Weekly, Monthly, GTD, etc.)
- Miniaturized preview: A tiny representation of the grid layout (columns with placeholder markers) — purely decorative, not interactive
- Description text (1-2 lines, `body.sm`)

**Flow**: Tap card -> Preview screen (shows full column list, allows editing column names before creation) -> "Create Board" button -> Navigate to new Board Matrix

### 5f. Onboarding

**4-screen carousel** (shown only on first launch):

**Screen 1 — Welcome**: App logo, tagline "See everything. Focus on one thing." Brief 2-line description. "Get Started" button.

**Screen 2 — The Grid**: Animated illustration showing a grid being populated with tasks and markers. Brief explanation: "List your tasks once. Mark them with dots in the columns where they're relevant."

**Screen 3 — Interactive Demo**: A miniature functional grid (3 tasks x 3 columns) that the user can actually tap to cycle markers. Instructional text: "Tap a cell to mark it. Tap again to change the status." This is the critical onboarding moment — the user must understand the tap-to-cycle mechanic before proceeding.

**Screen 4 — Start**: "Pick a template to create your first board" with 3 popular template options (Weekly, Monthly, GTD Contexts). Or "Skip" to go to empty board list.

**Navigation**: Horizontal swipe or next/back buttons. Dot indicators at bottom. Skip button in top-right on all screens except the last.

### 5g. Settings

**Layout**: Standard settings list (grouped sections).

**Sections**:
- **Appearance**: Theme picker (System / Light / Dark) with live preview
- **Board Defaults**: Default column set for new boards (editable list with drag-to-reorder)
- **Account**: Sign in / Sign up (if not authenticated), Account email and sync status (if authenticated), Sign out, Delete account (with double-confirmation)
- **Data**: Export boards (CSV/JSON), Import data
- **About**: App version, Open source licenses, "The Alastair Method" link, Feedback/support link

**Responsive**: Single column on phone. On tablet/desktop, settings list on left (320px), detail/preview pane on right.

---

## 6. Interaction Design Details

### 6a. Marker Tap Cycling

**Cycle sequence**: `empty -> DOT -> CIRCLE -> X -> empty`

**Per-tap behavior**:
1. User taps cell
2. Immediate: Ripple feedback from touch point (100ms)
3. 0-200ms: Current symbol scales to 130%, fades to 0% opacity
4. 100-200ms: New symbol appears at 0% opacity and 70% scale, animates to 100% opacity and 100% scale
5. Haptic: `HapticFeedback.lightImpact()` on mobile at the moment the new symbol reaches full scale
6. State update dispatched to Riverpod provider immediately on tap (optimistic)

**Visual continuity**: The color crossfades between the old marker color and the new marker color during the transition.

### 6b. Long-Press Marker Picker

**Trigger**: 300ms press-and-hold on any grid cell.

**Popup**: A floating container (horizontal row of 6 marker symbols + empty/clear option) positioned:
- Above the cell if there's room, below otherwise
- Horizontally centered on the cell, clamped to screen edges
- Size: ~280px wide x 56px tall
- Background: `surface.secondary` with elevation shadow
- Corner radius: `radius.sm`

**Behavior**:
- Finger can slide to select (like iOS long-press menus)
- Release on a symbol: applies that marker, popup dismisses
- Release outside popup: cancels, popup dismisses
- Haptic: `HapticFeedback.selectionClick()` as finger slides over each option

**Dismiss**: Tap outside, release gesture, or press Back/Escape.

### 6c. Swipe-to-Complete

**Direction mapping**:
- Swipe right: Complete task (state = COMPLETE)
- Swipe left: Cancel task (state = CANCELLED)

**Threshold**: 40% of the task row width. Below threshold, the row snaps back.

**Visual feedback**:
- Right swipe: Green (`swipe.complete`) background revealed behind the row, checkmark icon appears
- Left swipe: Red (`swipe.cancel`) background, X icon appears
- Row translates horizontally following the finger
- At threshold, haptic bump (`HapticFeedback.mediumImpact()`)
- Past threshold: Icon scales up slightly, confirming the action will trigger on release

**After completion**:
- Row animates strikethrough (see Section 4f)
- After 300ms, an undo snackbar appears at the bottom: "[Task name] completed. UNDO"
- Snackbar auto-dismisses after 4 seconds
- Undo reverses the state change and removes the strikethrough

### 6d. Drag-to-Reorder

**Activation**: Long-press (500ms) on the task row label, or grab the drag handle icon (visible on hover/web).

**Pickup animation**:
- Row lifts: Scale to 102%, elevation shadow fades in (0 to 4dp), 150ms
- Original position: Dashed-border placeholder appears (same height as row)
- Other rows animate up/down to make room as the dragged item moves

**While dragging**:
- The dragged row follows the finger/cursor vertically
- A thin horizontal line (2px, `action.primary` color) appears between rows to indicate drop position
- Auto-scroll: When the dragged item is within 60px of the top or bottom edge of the scrollable area, the list auto-scrolls in that direction at a rate proportional to proximity

**Drop**:
- Release: Row animates to new position (scale 102% to 100%, shadow 4dp to 0, 200ms with slight bounce)
- Placeholder disappears
- Position values updated and persisted

**Cancel**: Drag back to original position, or press Escape (web). Row animates back with the same bounce.

### 6e. Pinch-to-Zoom on Mobile

**Enabled via** `InteractiveViewer` widget.

**Scale limits**: 0.5x to 2.5x (configurable per board type — monthly boards may default to 0.7x to fit more columns).

**Gesture conflict resolution**:
- Two fingers: Pinch-to-zoom and pan (handled by `InteractiveViewer`)
- Single finger horizontal: Scroll columns (handled by horizontal `ScrollController` inside `InteractiveViewer`)
- Single finger vertical: Scroll tasks (handled by vertical `ScrollController`)
- Single finger tap: Marker cycle (handled by `GestureDetector` on `GridCell`)
- Priority: `InteractiveViewer` only activates on two-finger gestures. Single-finger gestures pass through to the inner scroll views and tap handlers.

**Reset**: Double-tap anywhere on the grid to reset to default scale (animated, 300ms).

### 6f. Keyboard Navigation on Web

**Focus system**: Grid cells are focusable. A visible focus ring (2px `border.focus` color, 2px offset inset) indicates the currently focused cell.

**Key bindings**:

| Key | Action |
|---|---|
| Arrow keys | Move focus between cells (wraps at edges) |
| Space | Cycle marker on focused cell |
| Enter | Open long-press marker picker for focused cell |
| Tab | Move focus to next interactive element outside grid |
| N | Open new-task input (focus moves to task name field) |
| Cmd/Ctrl+Z | Undo last action |
| Escape | Close any open popup/sheet, or deselect cell |
| Delete/Backspace | Clear marker from focused cell |

**Focus entry**: Pressing Tab or clicking any cell enters the grid focus mode. First cell focused is row 1, column 1 (or the today column if in time mode).

---

## 7. Platform-Specific Design Decisions

### Material vs Cupertino

**Decision**: Use Material Design 3 (via Flutter's `Material 3` theme) as the unified design language across all platforms. Do not implement Cupertino-specific components. Rationale:
- The grid-based UI is unique enough that platform-native chrome is a small fraction of the experience
- Maintaining two component sets doubles design and engineering effort
- Material 3's `useMaterial3: true` with custom color scheme provides sufficient polish on iOS
- Exception: Use the platform-native date picker (`showDatePicker` on Android, `CupertinoDatePicker` on iOS) via `adaptive: true`

### Web-Specific Patterns

| Pattern | Spec |
|---|---|
| Hover states | All interactive elements show cursor change (`pointer`) and subtle background tint on hover. Grid cells show `grid.cellHover` background. Board cards show elevation increase (shadow). Buttons show darkened/lightened background. |
| Right-click menus | Task rows: Edit, Complete, Cancel, Migrate, Delete. Board cards: Edit, Archive, Delete. Column headers: Rename, Reorder, Delete. Implemented via `ContextMenuRegion` or custom `Listener` for secondary tap. |
| Cursor changes | `pointer` on clickable elements. `grab` on drag handles at rest, `grabbing` while dragging. `text` on editable text. `default` elsewhere. |
| Tooltips | All icon buttons have tooltips (on hover, 500ms delay). Grid column headers show full label on hover if truncated. |
| Keyboard shortcuts hint | Floating "?" button in bottom-left corner opens a keyboard shortcut cheat sheet overlay. |
| URL deep links | `/board/abc-123` loads directly into the board matrix. Shareable URLs for each board. |
| Browser tab title | Updates to "[Board Name] - AlPHA" when viewing a board. |

### Mobile-Specific Patterns

| Pattern | Spec |
|---|---|
| Haptic feedback | `lightImpact` on marker tap, `mediumImpact` on swipe threshold, `selectionClick` on marker picker slide, `heavyImpact` on destructive action confirmation |
| Edge gestures | Avoid relying on left-edge swipe for navigation (conflicts with iOS back gesture). Use explicit back button in toolbar. |
| Pull-to-refresh | Available on board list screen, triggers sync check |
| Safe areas | Respect safe area insets (notch, home indicator, status bar). FAB positioned above home indicator on iOS. |
| Orientation | Support portrait and landscape. In landscape on phone, the grid benefits from extra horizontal space; hide the bottom nav to maximize vertical space. |

---

## 8. Accessibility Requirements

### WCAG 2.1 AA Targets

| Criterion | Target | Implementation |
|---|---|---|
| 1.1.1 Non-text Content | All markers have text alternatives | Every `MarkerIcon` has a `semanticLabel` (e.g., "To Do", "In Progress", "Done", "Deadline", "Recurring", "Migrated") |
| 1.3.1 Info and Relationships | Grid structure conveyed to assistive tech | Use `Semantics` with `table`-like structure. Each cell announced as "[Task name], [Column label], [Marker status or empty]" |
| 1.4.3 Contrast (Minimum) | 4.5:1 for normal text, 3:1 for large text | All text/background combinations verified. Marker colors verified against both light and dark surfaces. |
| 1.4.11 Non-text Contrast | 3:1 for UI components | All marker symbols maintain 3:1 contrast against their cell background |
| 2.1.1 Keyboard | All functionality via keyboard | Grid navigation, marker cycling, task creation, all menu actions (Section 6f) |
| 2.4.7 Focus Visible | Visible focus indicator | 2px `border.focus` ring on all focusable elements |
| 2.5.5 Target Size | 44x44 CSS pixels minimum | All grid cells, buttons, and interactive elements meet this requirement |
| 2.3.1 Three Flashes | No content flashes more than 3x/sec | All animations are smooth transitions, no flashing |

### Screen Reader Announcements

| Element | Announcement Format |
|---|---|
| Board card | "[Board name], [type] board, [N]% complete, last modified [date]" |
| Grid cell | "Task: [title], Column: [label], Status: [marker name or 'empty']" |
| Marker change | "Changed to [marker name]" (live region announcement) |
| Task completion | "[Task name] completed. Undo available." |
| Migration step | "Step [N] of 4: [step title]" |

### Reduced Motion Support

When `MediaQuery.of(context).disableAnimations` is true (or `prefers-reduced-motion: reduce` on web):
- Marker cycle: Instant swap, no scale bounce
- Strikethrough: Instant application, no sweep animation
- Page transitions: Instant cut, no slide/fade
- Loading skeletons: Static gray blocks, no shimmer
- Drag-to-reorder: No pickup animation, instant position swap on drop

### Color Blindness Considerations

Markers rely on both **shape and color** for differentiation. This is by design — the Alastair Method's paper version uses only symbols. The digital version adds color as a secondary channel. The six symbols (dot, circle, X, star, tilde, arrow) are all geometrically distinct and remain differentiable under all color vision deficiency types.

Additional measure: In settings, offer a "High Contrast Markers" toggle that adds a text label abbreviation inside or adjacent to each marker (TD, IP, DN, DL, RC, MG).

---

## 9. Collaboration Points

### Design-Engineering Handoff Process

1. **Design completes a screen/flow** in Figma (all breakpoints, all states, light + dark)
2. **Design posts to the team channel** with a link to the Figma frame and a summary of what's new
3. **Handoff meeting** (30 min, 1x per sprint): Walk through new designs, answer questions, note any technical constraints engineers raise
4. **Engineers access specs** via Figma Dev Mode (inspect dimensions, colors, typography, assets)
5. **Design tokens** are exported as JSON and committed to the repo in `assets/design_tokens/` for reference (engineering maps to Dart constants)
6. **Animations** are delivered as written specs (this document) plus Rive/Lottie files where applicable

### Design Review Cadence

| Meeting | Frequency | Participants | Purpose |
|---|---|---|---|
| Design-Eng Sync | Weekly (30 min) | Designer + Eng Lead | Review in-progress implementations against specs, resolve discrepancies |
| Design Critique | Bi-weekly (45 min) | Designer + Stakeholder | Review upcoming designs, gather feedback, approve direction |
| Sprint Demo | End of sprint (30 min) | Full team | See implemented features, designer validates visual quality |
| Design QA Session | As needed | Designer + QA Engineer | Structured walkthrough of implemented screens vs Figma specs |

### Handling Design-Engineering Discrepancies

1. Engineer notices a spec is unclear or technically infeasible -> Files a "Design Clarification" ticket
2. Designer responds within 1 business day with either: updated spec, acceptable alternative, or escalation to the stakeholder
3. If a compromise is needed (e.g., performance constraints prevent a desired animation), document the decision in the ticket and update the Figma spec to match what was actually built
4. Never ship a screen that hasn't been visually validated by design. If timeline pressure forces this, create a "Design Debt" ticket for the next sprint.

### QA Visual Validation Process

1. QA uses a **screenshot comparison tool** (e.g., Maestro, or manual side-by-side) to compare implemented screens with Figma frames
2. Tolerance: 2px positional variance, 1-step color variance (e.g., `#E0E0E0` vs `#E1E1E1` is acceptable)
3. **Mandatory checks** per screen:
   - All 3 breakpoints (phone 390px, tablet 820px, desktop 1440px)
   - Both themes (light + dark)
   - All defined states (empty, loading, populated, error)
   - Accessibility: screen reader announces correct labels, focus ring visible
4. Visual defects are filed with: screenshot of implementation, screenshot of Figma spec, annotated differences

---

## 10. User Research Plan

### Internal Dogfooding

**Phase 1 (Week 5-6, after MVP Grid is functional)**:
- Distribute TestFlight/internal APK to 5-8 team members
- Each person uses AlPHA as their actual weekly task manager for 2 weeks
- Collect structured feedback via a shared form: "What confused you?", "What frustrated you?", "What delighted you?", "How does it compare to your current system?"
- Focus areas: grid interaction fluency, marker cycling discoverability, task management completeness

**Phase 2 (Week 9-10, after Polish phase)**:
- Expand to 15-20 internal users including non-technical stakeholders
- 3-week usage period (per Alastair Johnston's recommendation that the method needs 3 weeks to become habitual)
- Weekly pulse survey (3 questions, 2 minutes)
- Exit interview with 5 participants (30 min each)

### Usability Testing Protocol for Grid Interaction

This is the make-or-break UX. The grid must be intuitive within 30 seconds of first interaction.

**Test Design**:
- **Participants**: 8-10 people unfamiliar with the Alastair Method, mix of productivity app users and non-users
- **Method**: Moderated, task-based usability test (45 min each)
- **Environment**: Screen + face recording (with consent). Remote via video call or in-person.

**Task Scenarios** (in order of complexity):

1. "You have a weekly board open. Add a new task called 'Buy groceries'." (Tests FAB + task creation)
2. "Mark 'Buy groceries' as something to do on Wednesday." (Tests tapping a cell to add DOT marker)
3. "You've started working on 'Buy groceries'. Update its status for Wednesday." (Tests marker cycling: DOT -> CIRCLE)
4. "You finished 'Buy groceries'. Mark it as done." (Tests either: cycling to X, or swipe-to-complete. Note which path the user discovers first.)
5. "Move 'Send invoice' above 'Buy groceries' in the list." (Tests drag-to-reorder)
6. "Mark 'Call dentist' as a high-priority deadline." (Tests long-press marker picker — will users discover it without prompting?)
7. "This week is over. Move your unfinished tasks to next week." (Tests migration flow)

**Metrics**:
- Task completion rate (target: >90% for tasks 1-5 without hints)
- Time-on-task for first marker placement (target: <10 seconds)
- Error rate on marker cycling (target: <15% unintended state)
- Discovery rate for long-press picker (target: >50% without prompting — if below, consider adding a visual hint)
- System Usability Scale (SUS) score (target: >72, "good")
- Net Promoter Score (target: >30)

**Key Questions to Answer**:
- Do users understand the grid metaphor within the first minute?
- Is the tap-to-cycle sequence intuitive, or do users expect a different interaction (e.g., a popup on every tap)?
- Can users distinguish DOT from CIRCLE at the default cell size on phone?
- Do users discover swipe-to-complete organically, or do they look for a checkbox?
- Is horizontal scrolling obvious on boards with many columns, or do users not realize there are more columns?

**Iteration Plan**:
- Round 1 (Week 4): Test with wireframe prototype in Figma (before engineering builds)
- Round 2 (Week 7): Test with functional build (after MVP Grid is implemented)
- Round 3 (Week 10): Test with polished build (after dark mode, animations, onboarding)
- Changes from each round are incorporated before the next round

### Quantitative Validation (Post-Launch)

- Track marker tap success rate (taps that result in intended state vs. accidental cycles requiring undo)
- Track onboarding completion rate (what percentage finish all 4 screens vs. skip)
- Track migration wizard completion rate (what percentage complete all 4 steps vs. abandon)
- Track 3-week retention rate (per Alastair Johnston's success criterion)
- Funnel analysis: Board creation -> First task added -> First marker placed -> 7-day return -> 21-day return

---

## Appendix: Design Token Export Format

For engineering handoff, tokens are structured as:

```json
{
  "color": {
    "marker": {
      "dot": { "light": "#4A90D9", "dark": "#6AABF0" },
      "circle": { "light": "#F5A623", "dark": "#FFB94D" },
      "x": { "light": "#7ED321", "dark": "#9AE649" },
      "star": { "light": "#D0021B", "dark": "#FF4D4D" },
      "tilde": { "light": "#9013FE", "dark": "#B266FF" },
      "migrated": { "light": "#8B8B8B", "dark": "#ABABAB" }
    },
    "surface": {
      "primary": { "light": "#FFFFFF", "dark": "#121212" },
      "secondary": { "light": "#F5F5F5", "dark": "#1E1E1E" },
      "tertiary": { "light": "#FAFAFA", "dark": "#2A2A2A" }
    }
  },
  "typography": {
    "heading.xl": { "size": 28, "weight": 700, "lineHeight": 36, "letterSpacing": -0.5 },
    "body.md": { "size": 14, "weight": 400, "lineHeight": 20, "letterSpacing": 0 },
    "grid.cell": { "size": 16, "weight": 600, "lineHeight": 16, "letterSpacing": 0 }
  },
  "spacing": {
    "xxs": 2, "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24, "xxl": 32, "xxxl": 48
  }
}
```

This maps directly to the Dart constants in `lib/design_system/theme/`.

---

### Critical Files for Implementation

- `/Users/alastairdrong/wip/AlPHA/docs/the-alastair-method.md` - Product specification defining the core data model, marker system, and UX requirements that all design decisions derive from
- `/Users/alastairdrong/wip/AlPHA/docs/plan-flutter-app.md` - Frontend architecture defining the widget tree structure (Section 3.2), responsive breakpoints (Section 4.1), design token structure (Section 8), and phased delivery timeline that the design sprint schedule must stay ahead of
- `lib/design_system/theme/` (to be created) - Target directory where design tokens will be implemented as Dart constants (`AppColors`, `AppTypography`, spacing values), directly informed by the token specification in Section 4
- `lib/design_system/components/` (to be created) - Target directory for the reusable component library (`MarkerIcon`, `GridCell`, `TaskRow`, `AlphaCard`), implementing the component specs from Section 4d
- `lib/features/board/presentation/widgets/` (to be created) - Target directory for the Board Matrix widget tree (`BoardMatrixView`, `MarkerCell`, `TaskRowLabel`, `ColumnHeaderCell`), the most design-critical implementation area