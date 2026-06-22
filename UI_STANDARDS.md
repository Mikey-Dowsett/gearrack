# GearRack UI Standards

This document defines the visual system and component conventions for the GearRack app. It centralizes tokens (colors, typography, spacing, radii), component styling, and usage guidance so UI across the app is consistent and easy to maintain.

Files to know
- `lib/theme/app_colors.dart` — color palette and `AppColors.of(context)` semantic accessor.
- `lib/theme/app_text_styles.dart` — canonical text styles using Google Fonts (Nunito).
- `lib/theme/ui_constants.dart` — spacing, radii, stroke widths, and other layout tokens.
- `lib/theme/app_theme.dart` — Material `ThemeData` for light/dark modes; includes component themes (inputs, buttons, chips, cards, appbar, bottom nav).

Principles
- Use tokens, not magic numbers. Prefer `AppTextStyles`, `AppColors.of(context)` or `AppColors.*` and `UiConstants` values over hard-coded sizes, colors, or radii.
- Prefer semantic colors from `AppColors.of(context)` when styling widgets so colors adapt correctly for light/dark modes.
- Keep component-level tweaks minimal. If a new variant is needed, prefer adding a new style in `app_theme.dart` instead of ad-hoc inline modifications.

Tokens
- Spacing: `UiConstants.spacingXS/S/M/L/XL`
- Radii: `UiConstants.borderRadius`, `UiConstants.cardRadius`, `UiConstants.chipRadius`, `UiConstants.buttonRadius`
- Stroke width: `UiConstants.borderWidth`
- Icon sizes: `UiConstants.iconSmall/Medium/Large`
- Input height / avatar sizes: `UiConstants.inputFieldHeight`, `UiConstants.avatarSize`

Color palette (semantic)
- Access semantic colors with `final colors = AppColors.of(context);` then use `colors.primary`, `colors.surface`, `colors.onSurface`, `colors.background`, `colors.textPrimary`, etc.
- For rare, static references use `AppColors.*` constants (e.g. `AppColors.lightPrimary`) only if you know you require a concrete palette.

Typography
- Use `AppTextStyles` for text: `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`.
- These styles use Nunito via `google_fonts` and are tuned for the app. To adjust sizes or weights, edit `lib/theme/app_text_styles.dart`.

Components (summary)
- Input fields
  - Use themed `InputDecoration` (provided by `AppTheme`) — filled, 12px content padding, 10px corner radius, 2px border.
  - Use `TextFormField` with `style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface)` and `decoration.hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)`.

- Buttons
  - Elevated: primary background (`colors.primary`) with `onPrimary` foreground. Rounded 10px radius, 0 elevation, padding 16×12.
  - Outlined: thin border (2px) in `colors.border`, rounded 10px radius.
  - Text button: use `colors.primary` for foreground.

- Chips
  - Neutral chips: background `colors.surface`, selected color `colors.primary`, chip radius 20px.
  - Use `FaIcon` or icons sized via `UiConstants.iconSmall`/`iconMedium`.

- Cards
  - Surface color: `colors.surface`, radius 10px, elevation 2.

- App bar
  - Raised surface: `colors.surfaceRaised`, title centered by default, 0 elevation, `AppTextStyles.titleMedium`.

- Bottom Navigation
  - Background: `colors.surfaceRaised`, selected color `colors.primary`, unselected `colors.textSecondary`.

Migration notes / Fixing inconsistencies
- Replace magic radii and paddings with `UiConstants` values. Common patterns found in the repo:
  - `BorderRadius.circular(10.0)` -> `BorderRadius.circular(UiConstants.borderRadius)`
  - `BorderRadius.circular(20)` for chips -> `UiConstants.chipRadius`
  - `border width 2.0` -> `UiConstants.borderWidth`
- Prefer `AppColors.of(context)` over hard-coded color values so widgets automatically adapt to dark mode.
- Prefer `AppTextStyles` for all text. When a color override is needed, use `.copyWith(color: colors.onSurface)`.

How to use in a widget (examples)

Text field example

```dart
final colors = AppColors.of(context);

TextFormField(
  style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface),
  decoration: InputDecoration(
    hintText: 'Name',
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
    // border/padding come from app theme's InputDecorationTheme
  ),
)
```

Choice chip example

```dart
final colors = AppColors.of(context);

ChoiceChip(
  label: Text('Daypack', style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
  selectedColor: colors.primary,
  backgroundColor: colors.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.chipRadius)),
)
```

Button example

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Save', style: AppTextStyles.bodyMedium),
)
```

Developer workflow
- When creating or updating UI, check `UI_STANDARDS.md` and prefer tokens and theme styles.
- If you need a new token (spacing, radius, color), add it to `lib/theme/ui_constants.dart` or `app_colors.dart` and document it here.
- Run the app in both light and dark modes to verify color contrast and accessibility.

Where to look for inconsistencies
- Search for raw numbers like `10.0`, `20`, `2.0` in UI code and replace with constants.
- Search for `Color(` or `Colors.` used directly in widget files; prefer `AppColors.of(context)`.
- Search for `TextStyle` instantiations outside `app_text_styles.dart`.

Contact
- If you want adjustments to type scale, radii, or color accents, change the tokens in `lib/theme/*` and the rest of the app will follow.

---

This file was added as part of a cleanup to centralize visual tokens and component theming. Follow these standards for consistent UI going forward.