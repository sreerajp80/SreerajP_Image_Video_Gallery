# Change Log: Trash Screen & Settings Card Layout

**Plan:** [plans/20260906_150413_trash_settings_cards.md](plans/20260906_150413_trash_settings_cards.md)

## Summary of Changes

1. Implemented a complete Trash Screen allowing users to view, restore individual items, restore all items, or empty all trashed items.
2. Restructured the Settings screen into a clean hub of category cards matching the Help section styling. Each card navigates to a dedicated sub-screen.

### Part A — Trash Screen
1. **Smart Album Service (`lib/services/albums/smart_album_service.dart`)**:
   - Registered `AlbumType.smartTrash` under key `'trash'`.
   - Included `smartTrash` in `SmartAlbumService.all()`.
2. **Media DAO (`lib/repositories/database/media_dao.dart`)**:
   - Added `restoreAllFromTrash()` to unmark all trashed items.
   - Added `deleteAllTrashed()` to remove trashed entries from the local database.
   - Added `getTrashCount()` to query total trashed count.
3. **Media Repository (`lib/repositories/media_repository.dart`)**:
   - Added `restoreAllFromTrash()`, `emptyTrash()`, and `getTrashCount()` methods.
4. **Trash Providers (`lib/providers/trash_providers.dart`)**:
   - Added `trashMediaProvider`, `trashCountProvider`, and `TrashController` for managing trash state and bulk actions.
5. **Trash Screen (`lib/screens/trash/trash_screen.dart`)**:
   - Created dedicated screen showing trashed items in a media grid.
   - Added app bar actions for "Restore all" and "Empty trash" with confirmation dialogs.
6. **Album Card (`lib/widgets/albums/album_card.dart`)**:
   - Corrected mapping for `AlbumType.smartTrash` to use `l10n.smartAlbumTrash`.
7. **App Router (`lib/core/routing/app_router.dart`)**:
   - Added route constant `kRouteTrash = '/trash'` and registered `TrashScreen`.
8. **Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`)**:
   - Added English and Malayalam strings for trash actions, headers, and dialogs.

### Part B — Settings Card Layout
1. **Settings Hub (`lib/screens/settings/settings_screen.dart`)**:
   - Restructured layout to show category cards matching `HelpTopicCard` styling with icons, titles, subtitles, and chevron indicators.
   - Added cards for Appearance, Language, Safety, Default App, Privacy, Help & Guides, About, and Reset Settings.
2. **Settings Sub-Screens**:
   - `lib/screens/settings/appearance_settings_screen.dart`: Theme picker, grid density slider, and flashbacks toggle.
   - `lib/screens/settings/language_settings_screen.dart`: System, English, and Malayalam selection.
   - `lib/screens/settings/safety_settings_screen.dart`: Destructive confirmation toggle.
   - `lib/screens/settings/default_app_settings_screen.dart`: Instructions and button to open Android system default apps.
   - `lib/screens/settings/privacy_settings_screen.dart`: Offline privacy notice, vault settings link, and backup link.
   - `lib/screens/settings/help_settings_screen.dart`: Help topics list with cards navigating to topic guides.
   - `lib/screens/settings/developer_settings_screen.dart`: Media indexing diagnostic tools for dev flavor.
3. **App Router (`lib/core/routing/app_router.dart`)**:
   - Registered all settings sub-routes under `/settings/`.
4. **Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`)**:
   - Added card subtitle strings in both English and Malayalam.

### Tests
1. `test/services/albums/smart_album_service_test.dart`: Updated to test 7 smart albums including trash.
2. `test/repositories/album_repository_test.dart`: Updated smart album count expectation to 7.
3. `test/repositories/database/media_dao_test.dart`: Added tests for `restoreAllFromTrash`, `deleteAllTrashed`, and `getTrashCount`.
4. `test/providers/trash_providers_test.dart`: Added unit tests for trash providers and `TrashController`.
5. `test/widgets/settings/settings_screen_test.dart`: Updated widget tests for the new hub cards and sub-screens.

## Verification
- `flutter analyze`: Completed with 0 issues.
- `flutter test`: All 1,828 tests passed.
- `dart format .`: Formatted all changed files.
