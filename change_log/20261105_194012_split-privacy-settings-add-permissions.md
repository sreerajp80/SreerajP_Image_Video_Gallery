# Split the privacy settings screen and add a Permissions screen

Implements plan: `plans/20261105_193139_split-privacy-settings-add-permissions.md`

## What changed

### Privacy screen
- `lib/screens/settings/privacy_settings_screen.dart` now holds only **Hide content** and
  **Vault settings**. The "No remote server" row and the "Backup and restore" row are gone.
- The title is now "Privacy" (was "Storage and privacy"). Its card subtitle on the main
  Settings screen is now "Hide content and vault" (was "Vault, backup, network policy").

### Settings hub
- `lib/screens/settings/settings_screen.dart` has two new cards after Privacy:
  - **Permissions**, which opens the new screen.
  - **Backup and restore**, which opens the existing backup screen (`/backup`) directly. No new
    screen was needed, and it reuses the existing text keys.

### New Permissions screen (`/settings/permissions`)
- `lib/screens/settings/permissions_settings_screen.dart` — new, read-only.
  - At the top, the "No remote server" statement, moved here from the Privacy screen
    (same text keys).
  - Three groups: **You allow these** (photos and videos, camera), **Granted at install**
    (fingerprint, local network, Wi-Fi details, network state, Wi-Fi suggestions, app-private
    messages), **Removed on purpose** (keep phone awake, record sound, write to storage).
  - Each row shows a short name, the reason, and the Android permission names, with
    "Android 14+" / "Up to Android 12" style notes where the manifest limits a name.
  - The photos and videos row shows the live state (Allowed / Selected only / Not allowed)
    from the existing `mediaPermissionStatusProvider`.
  - An "Open settings" button opens Android's page for this app, through the existing
    `MediaPermissionService.openSettings()`.
- `lib/models/settings/app_permission_info.dart` — new immutable model.
- `lib/core/constants/app_permissions.dart` — new list of all entries.
- `lib/core/routing/app_router.dart` — new route `kRouteSettingsPermissions`.

### Text
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` — two values changed and 34 new keys,
  in all three languages. Generated files refreshed with `flutter gen-l10n`.
- **The new Sanskrit text needs the owner's review**, the same as G9.

### Tests and docs
- `test/core/constants/app_permissions_test.dart` — new. Reads the manifest and fails if a
  declared or removed permission is missing from the list, if the list has an extra one, or if a
  `maxSdkVersion` does not match.
- `test/screens/settings/settings_screen_test.dart` — updated the hub and Privacy tests; added
  Permissions screen tests (groups, Android names, live state, all three languages).
- `docs/security.md` §11 — notes that the in-app Permissions screen mirrors the table, and the
  guard test that keeps it in step.

## Checks

- `flutter gen-l10n` — done.
- `dart format` on changed files — done.
- `flutter analyze` — no issues.
- `flutter test` — all 2,215 tests passed.
- Not checked on a real device yet.

## Security impact

No new permission, no manifest change, no new package, no network change.
