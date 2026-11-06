# Split the privacy settings screen and add a Permissions screen

**Status:** completed

## The issue

The settings screen at `/settings/privacy` is called "Storage and privacy", but it has
nothing about storage. It puts four different kinds of items in one card:

1. "No remote server": a statement, not a setting, but it looks like one.
2. "Hide content": a real on/off setting.
3. "Vault settings": a link to another screen.
4. "Backup and restore": a link to another screen.

Backup has nothing to do with privacy, so users will not look for it here. The app also
has no screen that tells the user which Android permissions it holds and why.

## What the owner asked for

- Rename the screen to **Privacy**. Keep only **Hide content** and **Vault settings** on it.
- Give **Backup and restore** its own place.
- Remove the **No remote server** item from this screen.
- Add a **Permissions** screen that lists every permission the app uses, both the ones the
  user allows (explicit) and the ones Android grants at install (implicit).

## The fix

### 1. Privacy screen
- Title becomes "Privacy" (`titleSettingsPrivacy`, all three languages).
- The card keeps only "Hide content" and "Vault settings".
- The "No remote server" row and the "Backup and restore" row are removed from this screen.
- The subtitle of its card on the main Settings screen becomes "Hide content and vault"
  (`descSettingsPrivacySubtitle`). The old one said "Vault, backup, network policy".

### 2. Backup and restore
- No new screen is needed. The backup screen already exists at `/backup`.
- Add a new "Backup and restore" card on the main Settings screen that opens it directly.
  It reuses the existing keys `titleBackupOpen` and `descBackupOpenSubtitle`, so it needs
  no new text.

### 3. "No remote server" text
- The owner asked to remove it from the Privacy screen. It is removed from there.
- Recommendation: show the same text once, at the top of the new Permissions screen. That is
  where a user asks "why does a gallery need internet?", and this text answers it. It reuses
  the existing keys `titlePrivacyNoServer` and `bodyPrivacyNoServer`, so no new translation.
- If the owner wants it gone from the app completely, the two keys are deleted instead.

### 4. New Permissions screen (`/settings/permissions`)
A read-only list. Each row shows a short friendly name, the Android permission name(s) in
small grey text, and one line on why the app needs it.

**You allow these** (explicit, Android asks you):
| Row | Android names | Why |
|-----|---------------|-----|
| Photos and videos | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED` (Android 14+), `READ_EXTERNAL_STORAGE` (Android 12 and below) | Show your photos and videos. This row also shows the live state: Allowed / Selected only / Not allowed, from the existing `mediaPermissionStatusProvider` |
| Camera | `CAMERA` | Scan the pairing QR code on the transfer screen only. Never takes a photo |

**Granted at install** (implicit, no prompt):
| Row | Android names | Why |
|-----|---------------|-----|
| Fingerprint and face unlock | `USE_BIOMETRIC`, `USE_FINGERPRINT` (Android 9 and below) | Unlock the vault |
| Network access | `INTERNET` | Local transfer to a phone on your own Wi-Fi only. Never the internet |
| View Wi-Fi details | `ACCESS_WIFI_STATE` | Read this phone's own Wi-Fi address for the pairing code |
| View network state | `ACCESS_NETWORK_STATE` | Part of the local transfer set. Not used to go online |
| Suggest Wi-Fi networks | `CHANGE_WIFI_STATE` | Offer a scanned Wi-Fi code to Android. You still pick the network yourself |
| App-private messages | `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Added by an Android library. Keeps the app's own internal messages private. Gives no access to anything |

**Removed on purpose** (libraries ask for these, the app strips them out):
`WAKE_LOCK`, `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`, each with a one-line reason.
This is honest and cheap, and shows the user what the app chose *not* to take.

At the bottom: an "Open Android app settings" button. It uses the existing
`MediaPermissionService.openSettings()`; no new platform code.

A new card "Permissions" on the main Settings screen opens it.

**Where the data lives (layers):**
- `lib/models/settings/app_permission_info.dart` — immutable model: an id enum, the list of
  Android names, and a kind (`explicit`, `implicit`, `removed`), plus an optional
  "Android version" note.
- `lib/core/constants/app_permissions.dart` — the constant list of all entries.
- The screen maps each id to its localized name and reason. No logic, no file or channel
  access in the widget; the live media state comes from the existing provider.
- Android permission names are shown as literals. They are fixed technical identifiers, like a
  code, not user text to translate.

**Guard test:** a test reads `android/app/src/main/AndroidManifest.xml` and fails if a
`uses-permission` there is missing from the list, or if a list entry is not in the manifest.
So the screen can never drift from the real manifest.

### 5. Main Settings screen order
Appearance, Language, Safety, Default gallery, Privacy, **Permissions**, **Backup and
restore**, Help, About, (Developer), Reset.

## Files to change

- `lib/screens/settings/privacy_settings_screen.dart` — remove two rows.
- `lib/screens/settings/settings_screen.dart` — new Permissions and Backup cards.
- `lib/screens/settings/permissions_settings_screen.dart` — **new**.
- `lib/models/settings/app_permission_info.dart` — **new**.
- `lib/core/constants/app_permissions.dart` — **new**.
- `lib/core/routing/app_router.dart` — new route `kRouteSettingsPermissions`.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` — changed title/subtitle, about 30 new
  keys (screen title, card subtitle, 3 section headings, 8 row names, 8 reasons, 3 removed
  reasons, 3 status labels, Android-version notes, settings button if no key exists yet).
  Then `flutter gen-l10n`.
- `test/screens/settings/settings_screen_test.dart` — update the Privacy test; add Permissions
  screen tests and the new hub cards.
- `test/core/constants/app_permissions_test.dart` — **new** manifest guard test.
- `docs/security.md` §11 — one line: the Permissions screen mirrors this table, and a test
  keeps it in step with the manifest.

## Language note

New Sanskrit text needs the owner's review, the same as G9. It will follow the glossary in
`docs/guidelines/language_packs/sanskrit_malayalam.md` §4.4. Labels stay short (§8.6).

## Security impact

No new permission, no manifest change, no new package, no network change. The new screen only
reads a constant list and the existing media-permission state. It makes the permission use
more visible to the user.

## Checks

`flutter gen-l10n`, `dart format .`, `flutter analyze` (zero issues), `flutter test`.
