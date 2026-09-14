# GearRack Design Philosophy

> **Single source of truth for the GearRack visual design language.**
> UI code that contradicts this document is a bug — fix the code, not the document.
>
> Last updated: 2026-09-14

---

## 1. Identity & Personality

GearRack is a **tool for outdoor enthusiasts** who track, organize, and pack their gear. The visual personality reflects this:

| Attribute | Value |
|-----------|-------|
| Tone | **Utilitarian, warm, grounded** — not playful, not corporate |
| Inspiration | Field notebooks, trail signage, well-worn equipment |
| Feeling | Dependable, honest, slightly rugged, analog |
| Light mode | Warm vintage-paper backdrop (`#F0E8D8`) recalling aged canvas |
| Dark mode | Deep forest-night tones for low-light camp use |

Design is flat, gridded, and texture-forward. Every color, radius, and type weight serves readability and hierarchy. Decoration is minimal and functional.

---

## 2. Color Palette

### 2.1 Access

```dart
final colors = AppColors.of(context);
```

Use the semantic accessor everywhere. Never hardcode raw hex values in widget files.

**Only** use static `AppColors.*` constants when you truly need a fixed color regardless of theme (rare — almost always a mistake).

### 2.2 Semantic tokens (light & dark)

| Token | Light hex | Dark hex | Usage |
|-------|-----------|----------|-------|
| `primary` | `#385A41` | `#77B487` | Interactive elements, selected state, key accents |
| `onPrimary` | `#F2F9F3` | `#0B140D` | Text/icons on primary |
| `primaryContainer` | `#D0E7D4` | `#2B4431` | Elevated container variant (bags in pack) |
| `primaryMuted` | `#708F77` | `#6B9174` | Subtle primary-toned surfaces |
| `accent` | `#3A714B` | `#5CAD72` | Secondary call-to-action (gradient partner) |
| `onAccent` | `#FAF9F0` | `#0D1A10` | Text/icons on accent |
| `background` | `#F0E8D8` | `#131914` | Page/Scaffold backgrounds (warm vintage paper) |
| `onBackground` | `#2C271E` | `#ECE9E1` | Text directly on background |
| `surface` | `#FAF6EF` | `#1D251F` | Card, input, chip backgrounds |
| `surfaceRaised` | `#E5DFD3` | `#273129` | AppBar, bottom nav, elevated containers |
| `surfaceSunken` | `#DCD5C7` | `#323C34` | Depressed/empty progress areas |
| `onSurface` | `#2C271E` | `#ECE9E1` | Text/icons on surface |
| `textPrimary` | `#2C271E` | `#ECE9E1` | High-emphasis body text |
| `textSecondary` | `#5C564A` | `#B0ACA0` | Secondary labels, hints, metadata |
| `textDisabled` | `#867F73` | `#828175` | Disabled text |
| `border` | `#D2CBBE` | `#333C35` | Default borders, card outlines |
| `borderStrong` | `#BEB6A8` | `#465048` | Stronger dividers, vertical separators, bottom-nav top border |
| `secondary` | `#72804F` | `#96A672` | Secondary semantic (category tags) |
| `tertiary` | `#AE6739` | `#D99165` | Tertiary accent (warm highlight, section bars) |
| `tertiaryContainer` | `#F5D8C1` | `#5E402F` | Background for tertiary elements |
| `terracotta` | `#B86B46` | `#B86B46` | Weathered-tool patina accent (rare highlight) |
| `error` | `#B00020` | `#B00020` | Errors, destructive actions |

### 2.3 Status colors (shared, same in both themes) — earthy / desaturated

| Token | Hex | Meaning |
|-------|-----|---------|
| `statusNew` | `#5C8F68` | Muted sage — item is new |
| `statusGood` | `#85986A` | Muted olive — item is in good condition |
| `statusWorn` | `#B8915A` | Muted ochre — item shows wear |
| `statusRetired` | `#8A817A` | Warm grey — item is retired |

### 2.4 Dark-mode rule

All text that defaults to `AppColors.black` (`#000000`) is **wrong** in dark mode.
Use `colors.textPrimary` / `colors.onSurface` / `colors.onBackground` instead.
*(See known issue §11.1.)*

---

## 3. Typography

### 3.1 Font family — dual-face system

| Role | Font | Rationale |
|------|------|-----------|
| **Headings** | **Fraunces** (via `google_fonts`) | Old-style serif with ink traps and variable optical sizing. Characterful without being decorative — field-guide personality. |
| **Body / UI labels** | **Inter** (via `google_fonts`) | Clean utilitarian sans. W500 (Medium) for body readability; W400 (Regular) for labels. |

No fallback — both packages pinned in `pubspec.yaml`.

### 3.2 Type scale

All sizes use `flutter_screenutil` `.sp` for responsive scaling.

| Token | Size | Weight | Font | Usage |
|-------|------|--------|------|-------|
| `titleLarge` | 18.sp | W700 (Bold) | Fraunces | Page titles, hero numbers |
| `titleMedium` | 16.sp | W700 (Bold) | Fraunces | Section headers |
| `titleSmall` | 14.sp | W700 (Bold) | Fraunces | Card titles, modal headers |
| `bodyLarge` | 16.sp | W500 (Medium) | Inter | Input text, list item names |
| `bodyMedium` | 14.sp | W500 (Medium) | Inter | Default body, button labels |
| `bodySmall` | 12.sp | W500 (Medium) | Inter | Metadata, secondary info |
| `labelLarge` | 15.sp | W400 (Regular) | Inter | Form labels |
| `labelMedium` | 13.sp | W400 (Regular) | Inter | Small field labels |
| `labelSmall` | 11.sp | W400 (Regular) | Inter | Tiny badges, timestamps |
| `specMedium` | 14.sp | W600 (SemiBold) | IBM Plex Mono | Weight / litre readouts, tabular numbers |
| `specSmall` | 11.sp | W500 (Medium) | IBM Plex Mono, +0.6 tracking | Stamps, counts (`12 ITEMS TRACKED`), units |

### 3.3 Usage rules

```dart
// ✅ Always pair with a semantic color from context
Text('Hello', style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface));

// ❌ Never use AppTextStyles without a color override in widget code
// (The default color is AppColors.black — see §2.4.)
```

Exception: inside a `TextTheme` assigned to Material's `ThemeData`, the framework
provides correct color adaptation automatically.

---

## 4. Spacing & Layout

### 4.1 Spacing scale

All values defined in `UiConstants`. Use `.sp` via `flutter_screenutil` for responsive sizing.

| Token | px | Typical use |
|-------|----|-------------|
| `spacingXS` | 6.0 | Tight vertical gaps, chip spacing |
| `spacingS` | 8.0 | Between label and field, horizontal icon gaps |
| `spacingM` | 12.0 | Default padding inside cards, horizontal page padding |
| `spacingL` | 16.0 | Page edge padding, section spacing |
| `spacingXL` | 24.0 | Large section separators, bottom sheet padding |

### 4.2 Density

**Moderate.** Not compact (no dense data tables) and not airy (no hero whitespace).
Aim for ~56–72sp touch targets, 8–16sp gutters.

### 4.3 Page structure

- Page edges: `spacingM` (12.sp) horizontal padding
- Card padding internal: `spacingM` (12.sp) or `spacingL` (16.sp)
- Between form fields: `spacingM` (12.sp) vertical
- Between sections: `spacingL` (16.sp)

### 4.4 Paper texture

A `PaperTexture` widget (custom `NoisePainter`) adds fine, semi-transparent grain over background surfaces. Applied globally via `MaterialApp.builder`. Never applied over interactive content or text — it sits as a barely perceptible overlay to kill sterile digital flatness.

---

## 5. Radii & Borders

All values defined in `UiConstants`. Apply with `.sp`.

| Token | Value | Usage |
|-------|-------|-------|
| `borderRadius` | **6.0** | Input fields, general containers |
| `cardRadius` | **8.0** | Cards |
| `compactCardRadius` | **4.0** | Compact row cards (pack build items, trip detail items) |
| `chipRadius` | 20.0 | ChoiceChips, FilterChips |
| `buttonRadius` | **6.0** | Elevated, Outlined, Text buttons |
| `borderWidth` | **1.5** | All component borders |

Radii are varied by purpose to create visual rhythm — they are not all the same value.

> ⚠️ **Do not use off-token radii.** `BorderRadius.circular(5)` and raw values without `.sp` are violations.

### 5.1 Notebook-outline standard

All bordered components share a **full outline** style — a 1.5px `colors.border` stroke around the entire element, using the component's designated radius. This creates a unified field-notebook / sketchbook feel where every element is framed by a deliberate pencil-stroke-weight outline.

| Component | Border style | Exception |
|-----------|-------------|-----------|
| Cards | Full outline on `Card.filled.shape` side | Bag cards use `colors.primary` border instead of `colors.border` |
| Inputs | `OutlineInputBorder` (not `UnderlineInputBorder`) | Focused state uses `colors.primary` border |
| Chips | Border side on chip `shape` | Selected state uses `colors.primary` fill (border stays `colors.border`) |
| Elevated buttons | Full outline on `shape` side | Same `colors.border` as all other components |
| Outlined buttons | Full outline on `shape` side | Same width/color as Elevated |
| Text buttons | No border | Text-only, no container |
| Profile containers | Full `Border.all` on `BoxDecoration` | Same as cards |

**No component uses `UnderlineInputBorder` or an inner bottom-only border.** Every bordered element has a full outline.

---

## 6. Elevation & Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `cardElevation` | **0.0** | All cards (GearCard, PackCard, InfoCard, trip cards, compact cards) |
| Buttons | elevation 0 | Elevated buttons have flat appearance |
| AppBar | elevation 0 | App bars sit flush on content |
| BottomNavigationBar | elevation 0 | Flush with a 2px `borderStrong` top border as divider |

All surfaces are flat. No shadows. Distinction comes from border color, background tint, and gradient — never elevation.

---

## 7. Motion & Animation

### 7.1 Baseline

| Property | Value |
|----------|-------|
| Default duration | 300 ms |
| Short duration | 200 ms (micro-interactions) |
| Long duration | 400 ms (page transitions) |
| Default easing | `Curves.easeInOut` |
| Page transition easing | `Curves.easeInOut` (Material default) |

### 7.2 Where animations are used (current)

| Location | Animation | Compliance |
|----------|-----------|------------|
| Page pushes/pops | MaterialPageRoute slide (RTL push, LTR pop) | ✅ Default |
| FAB press | Material ink splash (built-in) | ✅ Default |
| Card taps | Material ink splash via GestureDetector | ✅ Default |
| Loading states | CircularProgressIndicator (theme-colored) | ✅ Already used |
| RefreshIndicator | Material pull-to-refresh | ✅ Already used |
| TabBarView swipe | Material smooth page swipe | ✅ Already used |

### 7.3 Where animations are needed (future)

| Location | Suggested animation | Priority |
|----------|-------------------|----------|
| Gear list → filter/sort | `AnimatedList` or `AnimatedSwitcher` when list reorders | Medium |
| Item added/removed from pack | Brief scale/fade on the affected row | Low |
| Empty state → populated | Crossfade the empty state with the list | Low |
| Bottom sheet open/close | Material modal bottom sheet (default) | Already built-in |

### 7.4 Rules

- No decorative/loop animations (spinners, confetti, pulsing backgrounds).
- All transitions must complete in ≤400 ms.
- Respect `MediaQuery.prefersReducedMotion` in future custom animations (Material routes do this automatically).

---

## 8. Iconography

| Source | Package |
|--------|---------|
| Primary | `font_awesome_flutter` (`FaIcon`) |
| Fallback | Material `Icons.*` (only for FABs: `Icons.add`) |

### 8.1 Icon sizes

| Token | Value | Usage |
|-------|-------|-------|
| `iconSmall` | 14.0 | Inline with text, chips |
| `iconMedium` | 18.0 | Section headers, list item icons |
| `iconLarge` | 24.0 | Standalone icons, empty states |

### 8.2 Icon colors

- Default: `colors.onSurface` or parent text color.
- Interactive: `colors.primary` when active.
- Category icons: resolved via `AppColors.parseHex(category.color)`.
- Never use raw `Colors.white` or `Colors.black` — use semantic palette.

---

## 9. Component Patterns

### 9.1 Cards — flat design

All cards use `UiConstants.cardElevation` (0). No shadows.

```dart
Card.filled(
  color: colors.surface,
  elevation: UiConstants.cardElevation,  // 0.0
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),  // 8.sp
    side: BorderSide(color: colors.border, width: UiConstants.borderWidth),  // 1.5px
  ),
  // ...
)
```

**Variants:**
- **Default card** — surface bg, 1.5px `colors.border` outline, 8px radius, elevation 0.
- **Bag card (in pack detail)** — `primaryContainer` bg, `primary` 1.5px outline, elevation 0.
- **Gradient-header cards** — PackCard & trip cards use a `primary→accent` gradient header for visual hierarchy.
- **Compact row card** — surface bg, 1.5px `colors.border` outline, 4px radius, elevation 0.

### 9.2 Input fields

Inputs use `OutlineInputBorder` (full outline) instead of `UnderlineInputBorder` — consistent with the notebook-outline standard (§5.1).

```dart
TextFormField(
  style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
  decoration: InputDecoration(
    hintText: '…',
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
    filled: true,
    fillColor: colors.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
    // border, enabledBorder, focusedBorder — inherited from theme
  ),
)
```

The `InputDecorationTheme` in `AppTheme` provides default `OutlineInputBorder`, radius (6), and width (1.5). Override only when a field genuinely differs. Focused state switches border color to `colors.primary`.

### 9.3 Buttons

| Variant | Background | Foreground | Radius | Border | Padding |
|---------|-----------|------------|--------|--------|---------|
| **Elevated** | `colors.primary` | `colors.onPrimary` | `buttonRadius` (6) | 1.5px `colors.border` | H:16, V:12 |
| **Outlined** | `colors.surface` | `colors.onSurface` | `buttonRadius` (6) | 1.5px `colors.border` | H:14, V:10 |
| **Text** | transparent | `colors.primary` | none | none | Material default |

**Bottom-sheet save buttons** follow the Elevated pattern.
Both use `buttonRadius` (6).

### 9.4 Chips

```dart
ChoiceChip(
  selectedColor: colors.primary,
  backgroundColor: colors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(UiConstants.chipRadius.sp),  // 20.sp
    side: BorderSide(color: colors.border, width: UiConstants.borderWidth),  // 1.5px
  ),
  showCheckmark: false,
)
```

Chips include an outline border (previously they had none) to match the notebook-outline standard. The border remains `colors.border` in both selected and unselected states.

### 9.5 AppBar

```dart
AppBar(
  backgroundColor: colors.background,   // blends with scaffold
  elevation: 0,
  centerTitle: true,
  title: Text('…', style: AppTextStyles.bodyMedium),
)
```

> Note: The theme default uses `surfaceRaised`. For page-level detail views (GearPage, PackPage, TripDetailPage),
> the AppBar deliberately uses `colors.background` to blend with the scaffold. This is an intentional variant.

### 9.6 Bottom Navigation

```dart
BottomNavigationBar(
  elevation: 0,
  backgroundColor: colors.surfaceRaised,
  selectedItemColor: colors.primary,
  unselectedItemColor: colors.textSecondary,
  showUnselectedLabels: true,
)
```

The bottom nav sits flush with the scaffold, demarcated by a 2px `borderStrong` top border instead of a shadow.

### 9.7 Weight headers (pack detail / trip detail)

Primary-colored banner with:
- Icon badge (small `primaryMuted` rounded square)
- "TOTAL PACK WEIGHT" / "TOTAL TRIP WEIGHT" label
- Large weight value + unit
- Category breakdown progress bar

The progress bar is a `ClipRRect` row of colored segments (category colors).

### 9.8 Compact row cards (pack build / trip detail items)

Used inside scrollable lists where space is tight (pack Build tab, trip item list).

```dart
Card.filled(
  color: colors.surface,
  elevation: UiConstants.cardElevation,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(UiConstants.compactCardRadius.sp),
    side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
  ),
  child: SizedBox(height: 56.sp, child: Row(/* icon | name+meta | weight */)),
)
```

**Bag card variant** (in pack detail): uses `primaryContainer` background,
`primary` 1.5px border, elevation 0.

**Build tab grouping:** pack Build lists group rows under one `SectionHeader` per category (master category order, unknowns last) — category icon + name + mono `count · weight` spec. Bag card stays first, outside groups.

### 9.9 Empty states

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('…', style: AppTextStyles.bodyMedium),
    SizedBox(height: 8),
    Text('…', style: AppTextStyles.bodySmall),
  ],
)
```

### 9.10 Form labels

Use `AppTextStyles.labelMedium.copyWith(color: colors.onBackground)` with an optional red `*` for required fields.

### 9.11 PRO mode cards (profile page)

**Upgrade card** (PRO inactive):
- Container with `colors.surfaceRaised` background, `colors.border` 1.5px border, `cardRadius` (8) radius.
- Crown icon in `colors.tertiary`, benefit list with `colors.primary` check icons.
- Primary elevated button ("Enable PRO Mode") at bottom.

**Active PRO card** (PRO active):
- Gradient container using `primary→accent` (same as gradient-header cards §9.1).
- Crown + "PRO Mode Active" title in `colors.onPrimary`.
- "ACTIVE" pill badge with `colors.onPrimary` at 20% alpha background.
- Trip count text in `colors.onPrimary` at 90% alpha.
- Two side-by-side buttons:
  - "Open Trips" — `TextButton` with `onPrimary` 15% alpha background.
  - "Deactivate" — `OutlinedButton` with `onPrimary` at 40% alpha border.
  Both use `buttonRadius` (6), `onPrimary` text.

**PRO gate overlay** (TripHistoryPage when PRO is off):
- Centered column with `tertiary` crown icon (48.sp), "PRO Feature" title, description body, primary elevated button linking to ProfilePage for activation.

All PRO cards follow the same color, radius, border, and typography tokens as other components. No new tokens introduced.

### 9.12 Section accent bars

Section titles and list metadata headers use a small 4px-wide `tertiary` left bar for visual hierarchy — like a field notebook tab. The bar sits immediately to the left of the text with a 6px gap.

### 9.13 Status indicator dots

GearCard condition reads as a **5sp side-strip** in the status color (olive `statusGood` / ochre `statusWorn` / grey `statusRetired`) at the card's left rail, before the icon tile. No dot, no stamp tag — glanceable from the list. Weights use `specMedium` (value) + `specSmall` (unit) for a scale-readout feel.

PackCard / trip headers use **solid `primary`** (not `primary→accent` gradient) with a 1.5px `border` bottom rule — trail-sign feel, less generated.

### 9.14 Trailhead chrome

List headers use trailhead voice inside a `TopoBackdrop` (faint contour lines): `Basecamp • 12 ITEMS TRACKED` / `Pack Out • 3 PACKS` / `Trail Log • 5 TRIPS` (Fraunces title + mono spec + 4px tertiary bar via `SectionHeader`), search hint `Search kit…`, empty state `Pack's empty — let's fix that / Log your first piece of kit below`, extended FAB `LOG`.

### 9.15 Patch chips

Category filters use `PatchChip` (`widgets/patch_chip.dart`): 6px radius (not pill), uppercase mono label, category-color icon, count badge, forest fill when selected. Counts always visible — no `name∙3` strings.

### 9.16 Detail hero (gear page, mirrors pack page)

Green `primary` hero: icon badge (`primaryMuted` 25sp tile), uppercase category label, Fraunces 25sp name (2-line clamp), mono brand · weight line, mono price · qty · age line, condition pill (`onPrimary` 20% alpha). Body grouped under `SectionHeader`s: Specifications / Condition & Kit / Field Notes (6-line clamp) / Trail Use. `InfoCard` takes `maxLines` (default 2).

### 9.17 Form shell (add/edit pages)

`FormShell` (`widgets/form_shell.dart`): plain centered AppBar, 12sp padded scroll body, shared 56sp primary bottom-sheet save button with check icon. `FormHero`: slim `primary` banner (icon badge + uppercase label + live name + mono spec, all ellipsis). Bodies grouped with `SectionHeader`: add-gear = Identity / Specifications / Condition & Kit (`PatchChip` category + condition pickers, status-color icons); add-pack = Pack; log-trip = Trip / Details / Items. Field labels uppercase mono (`specSmall`); short hints.

---

## 10. Do/Don't Summary

| ✅ Do | ❌ Don't |
|-------|----------|
| Use `AppColors.of(context)` for all colors | Hardcode `Color(0x…)`, `Colors.white`, `Colors.black` in widgets |
| Use `UiConstants.*.sp` for radii, spacing, and sizing | Use raw numbers like `8.0`, `5.0`, `20` without `.sp` or token |
| Use `AppTextStyles.*.copyWith(color: colors.*)` for text | Use `AppTextStyles.*` without a color override in widget code |
| Use `Card.filled` for cards | Use bare `Card` (unless there's a specific need for non-filled) |
| Use `UiConstants.borderWidth` for all borders | Use `width: 2.0`, `1.5`, etc. directly |
| Reuse `widgets/gear_card.dart`, `widgets/pack_card.dart`, `widgets/info_card.dart` | Duplicate component code locally in page files |
| Use `FontAwesomeIcons` via `FaIcon` | Use Material `Icons.*` except for FABs |
| Apply `ScreenUtilInit` wrapping for `.sp`/`.w`/`.h` to work | Use `.sp` outside the ScreenUtil context |

---

## 11. Known Issues & Migration Plan

### 11.1 `AppTextStyles` default color

**Issue:** All `AppTextStyles` getters use `AppColors.black` as default color.
This means any widget that uses `AppTextStyles.bodyMedium` without `.copyWith(color: …)`
will show black text in dark mode.

**Status:** Accepted convention — always use `.copyWith(color: colors.onSurface)` in widgets.
A future refactor could change the default to `null` or a theme-aware value.

### 11.2 Duplicate `InfoCard` in `trip_detail_page.dart`

**Status:** ✅ Resolved — removed local copy and now imports `widgets/info_card.dart`.

### 11.3 Duplicate form widget helpers

**Issue:** `_fieldLabel`, `_buildTextField`/`_buildLabeledField` patterns are replicated in
`add_gear.dart`, `add_pack.dart`, and `log_trip_page.dart` with slight differences
(contentPadding vertical: 14.sp vs 12.sp).

**Status:** Accepted for now. Future refactor should extract a shared `FormFieldBuilder` widget.

### 11.4 `profile_page.dart`

**Status:** ✅ Implemented — full PRO mode management with upgrade/active states, trip stats display, and navigation integration.

---

## 12. File Map

| File | Role |
|------|------|
| `lib/theme/app_colors.dart` | Color palette + semantic accessor |
| `lib/theme/app_text_styles.dart` | Type scale (Fraunces headings + Inter body) |
| `lib/theme/ui_constants.dart` | Spacing, radii, strokes, icon sizes, misc |
| `lib/theme/app_theme.dart` | Material ThemeData (light + dark) |
| `lib/widgets/gear_card.dart` | Gear list item card |
| `lib/widgets/pack_card.dart` | Pack list item card (gradient header) |
| `lib/widgets/info_card.dart` | Key-value info card for detail pages |
| `lib/widgets/paper_texture.dart` | Subtle paper grain overlay (NoisePainter) |
| `lib/database/app_settings_dao.dart` | App settings persistence (PRO mode toggle, weight unit, theme) |
| `docs/DESIGN_PHILOSOPHY.md` | **This file — canonical design reference** |

---

## 13. Updating This Document

1. Add new tokens/patterns only after they've been introduced and approved in code.
2. Bump the "Last updated" date at the top.
3. Codify patterns — not instances. A new component variant belongs in §9, not as a one-off rule.
4. If the codebase drifts from this document, fix the code (not the document) — unless the user explicitly decides the philosophy should change.
