# GearRack 🎒

A cross-platform Flutter application for managing your outdoor and camping gear. Track, organize, and pack your equipment with ease.

## Features

- **Gear Library** — Maintain a searchable inventory of all your gear with details such as brand, weight (in grams), price, purchase year, condition, and custom notes.
- **Pack Builder** — Create packs (packing lists) from your gear library. Check items off as you pack, with automatic sorting and quantity tracking.
- **Custom Categories** — Organize gear with user-configurable categories, each with its own icon and color.
- **Search & Filter** — Quickly find gear by name, category, or condition.
- **Cross-Platform** — Runs on Android, iOS, Linux, macOS, and Windows.
- **Local Data** — All data is stored locally using SQLite (via `sqflite`).

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Built-in `setState` / `StatefulWidget`
- **Database:** SQLite (`sqflite` / `sqflite_common_ffi`)
- **Icons:** Font Awesome (`font_awesome_flutter`)
- **Fonts:** Google Fonts (`google_fonts`)
- **Responsive Design:** `flutter_screenutil`

## Getting Started

1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (minimum SDK version: `^3.12.1`).
2. Clone the repository and navigate to the project directory.
3. Run `flutter pub get` to install dependencies.
4. Launch the app with `flutter run`.

## Project Structure

```
lib/
├── main.dart                   # App entry point and navigation
├── database/                   # SQLite DAO layer
│   ├── database_helper.dart    # Database initialization & singleton
│   ├── schema.dart             # Table definitions
│   ├── gear_item_dao.dart      # CRUD for gear items
│   ├── category_dao.dart       # CRUD for categories
│   ├── pack_item_dao.dart      # CRUD for pack items (join table)
│   ├── custom_list_dao.dart    # CRUD for custom lists
│   ├── custom_list_item_dao.dart
│   └── app_settings_dao.dart   # User preferences
├── models/                     # Data classes
│   ├── gear_item.dart          # Core gear item model
│   ├── pack_item.dart          # Pack-gear join model
│   ├── category.dart           # User-configurable categories
│   ├── condition.dart          # Item condition enum
│   ├── custom_list.dart        # User-defined lists
│   ├── custom_list_item.dart
│   └── app_settings.dart       # User preferences model
├── pages/                      # UI screens
│   ├── home_page.dart          # Main gear overview
│   ├── search_page.dart        # Search & filter
│   ├── profile_page.dart       # User settings
│   ├── gear_page.dart          # Gear item detail/edit
│   └── add_gear.dart           # Add new gear form
├── theme/                      # App theming
│   └── app_theme.dart          # Light & dark theme definitions
├── utils/                      # Helpers
└── widgets/                    # Reusable UI components
```
