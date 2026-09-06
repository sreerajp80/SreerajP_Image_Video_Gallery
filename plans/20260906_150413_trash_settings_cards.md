# Trash Screen & Settings Card Layout

**Status:** Approved

## Issue

1. No way to view or empty trashed items in the gallery.
2. Settings screen uses inline controls instead of tappable cards that navigate to sub-pages.

## Fix

### Part A — Trash Screen
- Register `smartTrash` in `SmartAlbumService`
- Add bulk trash operations to DAO and repository
- Create trash providers and a new `TrashScreen`
- Add routing and localization strings
- Fix album card label bug

### Part B — Settings Card Layout
- Restructure Settings screen into a hub of tappable cards
- Create sub-screens for each settings category
- Add new routes and localization strings

## Files to Change

### Part A
- `lib/services/albums/smart_album_service.dart` — register trash album
- `lib/repositories/database/media_dao.dart` — bulk trash DAO methods
- `lib/repositories/media_repository.dart` — bulk trash repository methods
- `lib/providers/trash_providers.dart` — [NEW] trash providers
- `lib/screens/trash/trash_screen.dart` — [NEW] trash screen
- `lib/core/routing/app_router.dart` — trash route
- `lib/widgets/albums/album_card.dart` — fix label bug
- `lib/l10n/app_en.arb` — trash strings
- `lib/l10n/app_ml.arb` — trash strings (Malayalam)

### Part B
- `lib/screens/settings/settings_screen.dart` — hub layout
- `lib/screens/settings/appearance_settings_screen.dart` — [NEW]
- `lib/screens/settings/language_settings_screen.dart` — [NEW]
- `lib/screens/settings/safety_settings_screen.dart` — [NEW]
- `lib/screens/settings/privacy_settings_screen.dart` — [NEW]
- `lib/screens/settings/default_app_settings_screen.dart` — [NEW]
- `lib/screens/settings/help_settings_screen.dart` — [NEW]
- `lib/core/routing/app_router.dart` — settings sub-routes
- `lib/l10n/app_en.arb` — settings card strings
- `lib/l10n/app_ml.arb` — settings card strings (Malayalam)
