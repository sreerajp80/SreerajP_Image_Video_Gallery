# Security — SreerajP Image Video Gallery

This document is the security design for the SreerajP Image Video Gallery app: threat model,
sensitive data, storage, crypto, permissions, logging, and the rules for the local transfer and
scanner features. Read it before you change storage, crypto, the vault, permissions, the
manifest, logging, backup, or anything that opens a socket or an intent. It follows the section
order of the shared blueprint; §19 and §20 are app-specific additions.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [architecture.md](architecture.md)
- [known_gaps.md](known_gaps.md)
- [guidelines/security.md](guidelines/security.md) (the blank template)

---

## 1. Security Scope

- **Application:** SreerajP Image Video Gallery (`in.sreerajp.imgvidgal`)
- **Data sensitivity:** high — private photos and videos, an encrypted vault, notes, and text
  read out of photos.
- **Platform:** Android only (minSdk 24, targetSdk 36).
- **Profiles in force:** `Core Baseline` + `Production App Extension` + `Sensitive Data
  Extension`, plus the app's own "local network only" rule (hard rule 2 in `CLAUDE.md`).

### 1.1 Security Baseline (Every App)

Each line is `verified` or `n/a` (with a reason), or `open` with the gap that blocks it. The rules
are in engineering standard §15.1. Re-check this list before every production release. No
release may ship while a line is `open` (store readiness §1).

**Last checked:** 2026-11-02, by reading the code and manifest. Not checked on a device.

| Area | Rule | Status |
|------|------|--------|
| Secrets | No real secrets in code, assets, `--dart-define` or native config | `verified` — no API keys or server keys exist; the app has no server. Keystore passwords stay in the git-ignored `android/key.properties` |
| Network | HTTPS only; certificate checks never disabled; cleartext off; timeouts set | `verified` (adapted) — there is no HTTP at all. The only sockets are the local transfer ones, encrypted with AES-256-GCM session keys (§19). No `badCertificateCallback` or `HttpOverrides`. `usesCleartextTraffic` is not set, so the platform default (off) applies. Connect timeout in `p2p_client_service.dart`; idle and pairing timeouts in `p2p_connection.dart` / `p2p_server_service.dart` |
| Tokens | Sign-in tokens and credentials only in platform secure storage | `n/a` — no accounts or sign-in. The vault PIN hash and keys are in `flutter_secure_storage` / Android Keystore (§4, §6) |
| Sign-in | OAuth/OIDC with PKCE, server enforces access | `n/a` — no accounts and no server |
| Outside input | Intents, imports, payloads, QR codes, platform channels validated (§3.1); parameterized SQL; no path traversal | `verified` — see §3.1. SQL uses `?` arguments; transfer file names go through `safeFileName` (§19.5) |
| Deep links | No sensitive action without user confirmation | `verified` — the only incoming links are "open with" `VIEW` intents. They only open the viewer; nothing is deleted, shared or changed without the user acting. No custom URL scheme |
| WebView | Not used, or locked down | `n/a` — the app has no WebView |
| Platform hardening | Components not exported unless needed; `PendingIntent` immutable; narrow `FileProvider`; private app folders | `verified` — only `MainActivity` is exported (§10); no `PendingIntent` in app code; `FileProvider` is limited to `cache/shared_media/` (2026-11-02); app data lives in app-private folders |
| Randomness / crypto | `Random.secure()` for security values; standard crypto libraries only | `verified` — no plain `Random()` in `lib/`; AES-GCM and PBKDF2 from maintained libraries and Android Keystore (§6) |
| Release build | No debug menus, test accounts or backdoors; `debuggable=false`; `--obfuscate` | `verified` — developer items in Settings show only in the `dev` flavor; `--obfuscate` is in every release command ([release_process.md](release_process.md) §6) |
| Third-party SDKs | Each SDK listed with what it collects | `verified` — every package and Android library is open source and listed in [dependencies.md](dependencies.md); none collects or sends data. Google ML Kit (via `mobile_scanner`) was removed on 2026-11-02 (G47); codes are read by ZXing core. `test/tool/dependency_policy_test.dart` fails on any blocked package anywhere in `pubspec.lock`, and on ML Kit or Play Services in the Gradle file |
| Data minimization | Only data that a feature needs is collected and kept | `verified` — nothing is collected; data stays on the device (§4, §13) |
| Web (if declared) | No secrets in the web bundle; CSP | `n/a` — Android only |

---

## 2. Security Objectives

1. **Local network only.** The app never contacts a remote server. No HTTP client, no cloud
   backend, no analytics, no telemetry, no update check. `android.permission.INTERNET` exists for
   the peer-to-peer transfer feature alone, which opens a socket only to another device on the
   same Wi-Fi. No media, metadata or diagnostics ever reach anywhere the user did not pair with
   by hand. See §19.
2. **Hardware-backed private vault.** Vault files are AES-256-GCM encrypted under a key held in
   the Android Keystore.
3. **Anti-forensic shredding.** Files leaving for the vault are overwritten before deletion.
4. **Screen protection.** `FLAG_SECURE` blocks screenshots, screen recording and the recent-apps
   preview on vault screens always, and on every screen when the user turns on "Hide content".
5. **Safe, non-destructive file operations.** `AtomicSaver` stages every write and swaps it in
   atomically.

---

## 3. Threat Model Summary

### In Scope Threats

- **Device theft or a casual look at an unlocked phone.** Mitigated by the biometric/PIN-gated
  vault, instant lock on background, and idle timeout.
- **Data leaving the device over the network.** Mitigated by having no HTTP client or cloud SDK,
  by the blocked-package list, and by `LocalAddressRules`, which refuses any socket to a
  non-private address. `INTERNET` **is** declared (Android needs it for any socket), so the
  guard is in code, not in the manifest. See §19.
- **Other apps reading private media.** Vault files live in app-private storage, outside
  MediaStore.
- **File recovery after deletion.** Mitigated by overwrite-then-delete shredding.
- **Screen capture.** Mitigated by `FLAG_SECURE` on vault screens, and on every screen with the
  "Hide content" setting.
- **Log leakage.** Secrets, media bytes, OCR text and notes are never logged; `toString()`
  methods hide them.
- **Hostile input.** Scanned codes, PDFs, backup files and transfer peers are treated as
  untrusted (§14, §19, §20).

### Out Of Scope Threats

- Rooted or compromised devices with kernel-level memory access.
- Lab attacks on hardware (side channels, chip extraction).
- Malicious or backdoored OS builds.

### 3.1 Entry Points And Attack Surface

Every way data or commands reach the app from outside, and how each is checked (engineering
standard §15.1, "Input from outside the app").

| Entry Point | Example | Validation | Sensitive Action Possible? |
|-------------|---------|------------|----------------------------|
| Android intent ("open with") | `ACTION_VIEW` for `image/*` or `video/*` from a file manager | `IncomingUriRules` (Kotlin) allows `content://` except this app's own provider, and `file://` only outside the app's data folders, checked on the canonical path. Checked again before `readBytes` and `loadThumbnail` (§10) | No — it only opens the viewer |
| Local transfer (peer phone) | Files and a manifest from a paired phone on the same Wi-Fi | `LocalAddressRules` refuses non-private addresses; pairing secret and authenticated handshake; byte length and SHA-256 checked; file names cleaned by `safeFileName`; staged in app-private storage (§19) | No — files are only added, after the user pairs by hand |
| File import (backup restore) | `.gallerybak` picked by the user | Picked through the system document picker; header authenticated; AES-256-GCM tag checked; restore only adds and updates (§14.5) | No — nothing is deleted |
| File import (PDF) | A PDF picked for image extraction | Treated as untrusted; size and structure limits in the parser (§20.5) | No |
| QR / barcode in an image | A code read from a photo by the in-image scanner | Only `http`, `https`, `tel`, `mailto`, `sms`, `geo` may launch, checked in Dart and again in Kotlin; Wi-Fi codes become a suggestion only (§20.1, §20.2) | No — the user taps to open, and Android asks again |
| Pairing QR code | Code shown by the other phone | Format and length checked before use; carries only the address, port and pairing secret (§19.2) | No |
| Platform channel | Calls between Dart and Kotlin | The channels are app-internal. Kotlin checks the arguments that matter (paths, URIs, schemes); a bad argument returns an error, not a crash | No |
| Media files on the device | Corrupt or hostile JPEG, video, RAW | Decoders run with fallbacks (hard rule 5); metadata parsers never throw to the UI | No |
| Clipboard | — | The app only writes to the clipboard (marked sensitive for Wi-Fi passwords); it never reads it | n/a |
| Deep link / app link, push, WebView, network API | — | Not present | n/a |

---

## 4. Sensitive Data Inventory

| Data Type | Example | Where It Exists | Protection |
|---|---|---|---|
| Vault media | Private photos and videos | App-private files (`.enc`) | AES-256-GCM, Keystore key |
| Vault encryption key | 256-bit AES key | Android Keystore | Hardware-backed; never leaves the Keystore |
| Vault PIN | User PIN | Memory only, briefly | Stored as a PBKDF2 hash + salt + iteration count in `flutter_secure_storage`; the PIN itself is never stored |
| Vault metadata | Original file name, size, tags, notes | `vault_items` table in the app database | App-private storage, `allowBackup="false"`. **Stored as plain text** — see §17 |
| Biometric state | Fingerprint / face | Android OS | Handled by `local_auth` / BiometricPrompt; the app never sees it |
| Media notes | Private markdown notes | `media_items.user_notes` | App-private storage; never logged |
| OCR text | Text read from a photo | Memory only, until the user copies or saves it | Never logged or written by itself |
| Wi-Fi password from a scanned code | Network password | Memory; clipboard only if the user asks | Never shown or logged; clipboard marked sensitive |
| Transfer pairing secret | 9 random bytes | Memory, one session | Never written to disk or logged |
| Backup archive | `.gallerybak` file | Where the user saves it | PBKDF2 + AES-256-GCM, password-derived |

---

## 5. Storage Model

### At Rest

- **Primary local storage:** `sqflite` database in app-private storage; vault files in
  app-private storage.
- **Secure key storage:** Android Keystore (vault key); `flutter_secure_storage` (PIN hash,
  salt, iteration count, vault settings), pinned to 11.2.0 with:
  - `migrateWithBackup: true`: a copy is kept while the plugin moves data to a new cipher;
  - `resetOnError: false`: the plugin's default wipes all data on a storage error, which here
    would erase the vault PIN.

  Version 11 cannot read version 9 data. That was safe here because no installed copy ever held
  a vault (owner's confirmation, G49).
- **Plain settings:** a JSON file in the app-support folder, holding only non-secret preferences,
  and `SharedPreferences` for one value: the language (`app_language`). Nothing secret is ever
  put in `SharedPreferences`.
- **Backup behavior:** `android:allowBackup="false"` and `data_extraction_rules.xml` (§10). The only
  way data leaves through the app is the user's own encrypted `.gallerybak` backup or a hand-paired
  transfer.

### In Memory

- Decrypted vault media and thumbnails live in memory only, never in a cache or temp file.
- Memory is cleared when the vault locks: at once on leaving the foreground, or after the idle
  timeout.
- The PIN, backup password and pairing secret are used and dropped.

### In Transit

- **Network use:** local Wi-Fi only, to a hand-paired phone (§19).
- **Transport protection:** AES-256-GCM on every frame under a session key derived from the
  pairing secret, with an HMAC challenge proving both sides hold it. No TLS is used, because
  there is no server and no certificate authority involved.

---

## 6. Cryptography Design

```text
User Biometric / PIN Auth
       │ (Success)
       ▼
Android Keystore Master Key (AES-256)
       │
       ▼
AES-256-GCM Cipher (Random 96-bit IV + 128-bit Auth Tag)
       │
       ▼
Encrypted Media Stream (.enc) in App-Private Storage
```

- **Encryption algorithm:** AES-256-GCM everywhere (vault, backup, transfer).
- **Key derivation:** PBKDF2-HMAC-SHA256 — 120 000 iterations for the vault PIN hash, 210 000
  for backup passwords. Transfer keys use HMAC-SHA256 over the pairing secret (§19.2).
- **Nonce / IV strategy:** a fresh random 96-bit IV for every file, thumbnail and frame. An IV is
  never reused under a key.
- **Format versioning:** the backup header has a version byte; the transfer handshake carries a
  protocol version; the PIN iteration count is stored so it can be raised later.
- **Legacy format support:** schema v2 added a separate IV for vault thumbnails. Older rows have
  none and are shown with no preview, never with wrong bytes.

### 6.1 Android Keystore master key

- The key is generated inside the Android Keystore with `KeyGenParameterSpec`
  (`PURPOSE_ENCRYPT | PURPOSE_DECRYPT`), so it cannot be read out of the device.

### 6.2 Anti-forensic file shredding

Before a file moves into the vault, or a vaulted file is removed:

1. Open the file for random-access writing.
2. Overwrite the whole file with zeroes, then with random bytes (2 passes by default, 1–5
   allowed, in 64 KB blocks).
3. Flush to disk.
4. Delete the file.

### 6.3 Zero cache leaks

- Vault thumbnails are decrypted into memory only.
- No decrypted vault frame or thumbnail is ever written to shared storage or
  `getTemporaryDirectory()`.

### Rules

- Keys, IVs, salts and passwords are never hard-coded.
- Randomness always comes from a secure generator (`SecureRandom` / `Random.secure()`).
- Every encrypted format is versioned.

---

## 7. Authentication And Access Control

- **App-lock strategy:** the vault only (the rest of the gallery shows the phone's own public
  media). Android BiometricPrompt with a PIN fallback.
- **Fallback behavior:** the PIN, checked against the PBKDF2 hash.
- **Session-expiry rule:** idle auto-lock after 30 s, 60 s (default) or 5 min, chosen by the user.
- **Background lock rule:** the vault locks at once on `inactive`, `hidden`, `paused` or
  `detached` (`VaultLockPolicy`, applied by `VaultAutoLockScope`).
- **Protected-route strategy:** `/vault` opens `VaultGateScreen`; nothing inside is shown until
  the user unlocks.
- **Lock screen implementation:** `lib/screens/vault/vault_gate_screen.dart`.

---

## 8. Binary Protections

### 8.1 Obfuscation

Every production release is built with:

```bash
--obfuscate --split-debug-info=build/symbols/android-prod-<version>/
```

Obfuscation raises the cost of reading the app. It is not a strong security boundary on its own.
The symbol files must be kept safe for the life of the release, never committed, and used only
to decode crash traces.

### 8.2 R8 / ProGuard

`isMinifyEnabled` and `isShrinkResources` are on for release in `android/app/build.gradle.kts`.
`android/app/proguard-rules.pro` keeps classes that are reached by reflection.

### 8.3 Debuggable flag

`android:debuggable` must be absent or `false` in the merged release manifest. Check it before
every release ([release_process.md](release_process.md) §6).

---

## 9. Logging And Telemetry Policy

### Never Log

- PINs, passwords, keys, IVs, salts, pairing secrets.
- Decrypted media, media bytes, thumbnails.
- OCR text, notes, Wi-Fi passwords, scanned code contents.
- Full database rows.
- File paths or names of vault items.

### Allowed Diagnostic Context

- Operation name and screen name.
- Error category (not a raw message that may hold user data).
- Counts and sizes (for example "OCR: 412 characters, `mal`").
- Every log line added for the silent-catch work (G31) names the operation only, such as
  "Saving a received file failed". None quotes a path, name, URI, note or metadata value. The
  error object is passed separately, and outside the dev flavor only its type is kept.
- **Known conflict, owner to decide:** in the dev flavor the logger keeps the full error, and an
  exception's text can quote a file path. `CLAUDE.md` says private metadata must not be logged
  "even in debug builds". See [known_gaps.md](known_gaps.md) G48.

### Logging Controls

- **Logger implementation:** `AppLogger` (`lib/core/logging/app_logger.dart`), writing through
  `dart:developer`. Nothing is written to a file. `print` and `debugPrint` are not used in `lib/`.
- **Verbose logging gate:** `trace` and `debug` produce output only in the dev flavor
  (`AppFlavorConfig`).
- **Log level in production:** `info` and above only.
- **Error objects:** outside the dev flavor an `error` passed to the logger is reduced to its type
  name (for example `FileSystemException`), because an exception message can quote a file path
  or content URI. Tested in `test/core/logging/app_logger_test.dart`.
- **Global handlers:** `FlutterError.onError` and `PlatformDispatcher.instance.onError` log
  through `AppLogger` under the same rules, and release builds show a neutral
  `SafeErrorFallback` instead of any exception text.
- **Redaction strategy:** sensitive models override `toString()` to hide their content
  (`OcrResult`, `MediaNote`, `PairingPayload`, Wi-Fi payloads).
- **Telemetry:** none. No analytics, crash reporting or remote logging, ever.

---

## 10. Platform Security Controls

### Android

- `android:allowBackup="false"` — turns off cloud backup. On Android 12 and above it does **not**
  stop device-to-device transfer, so it is not enough alone.
- `android:dataExtractionRules="@xml/data_extraction_rules"` — on Android 12 and above, excludes
  every app storage area from both cloud backup and device transfer. Everything is excluded, not
  only sensitive files, so a file added later is safe by default.
- `android:fullBackupContent="false"` — the matching setting for Android 11 and below.
- **Cost of this choice:** after a phone move the app starts empty. Shared photos and videos are not
  affected. The encrypted `.gallerybak` backup (§14) is the way to move app data.
- **Limit:** these settings cover the Android system path. A phone maker's own transfer tool or a
  rooted phone may not honour them. `test/android/backup_rules_test.dart` checks the settings are
  present; it does not run a real transfer.
- **Screenshot protection:** `FLAG_SECURE` set through the `vault` method channel by
  `SecureScreen`, on `VaultGateScreen`, `VaultScreen`, `VaultSettingsScreen` and
  `VaultViewerScreen`. It is released when those screens close. The "Hide content" setting
  (`AppSettings.protectAllScreens`, off by default) sets it for the whole app through
  `AppScreenProtection`; the vault stays protected whatever it says.
- `android:debuggable`: must be `false` in release (§8.3).
- **Exported components:** only the main activity is exported (it receives "open with"
  intents). The file provider is `exported="false"`.
- **Links from other apps:** `IncomingUriRules` checks every "open with" link, and again before
  `readBytes` and `loadThumbnail`. It allows `content://` except this app's own file provider, and
  `file://` only outside the app's data folders, using the canonical path. Everything else is
  refused. `file://` stays allowed because `publishFile` returns it on Android 9 and below.
- **Randomness:** GPS blurring uses `Random.secure()` by default, because the offset is what hides
  a home address.
- **Root detection:** none. Rooted devices are out of scope (§3).

### iOS

`N/A` — Android only.

### Windows

`N/A` — Android only.

---

## 11. Permissions

Our manifest declares exactly these 11 Android permissions, and nothing else. The merged release
manifest holds 12: these 11 plus `in.sreerajp.imgvidgal.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
`androidx.core` defines that one as a signature-level permission private to this app, so that
receivers it registers in code cannot be reached by other apps. It grants nothing to the app and
the user never sees it.
`WAKE_LOCK` (added by ExoPlayer) is removed with `tools:node="remove"`. So are `RECORD_AUDIO` and
`WRITE_EXTERNAL_STORAGE`, which the `camera` plugin asks for: the pairing scan only reads preview
frames, never records sound and never writes a file. The plugin's `camera.any` feature is marked
not required, so a phone with no camera can still install the app and pair by typing the code.

| Permission | Why It Is Needed | Requested When | Denial Handling |
|---|---|---|---|
| `READ_MEDIA_IMAGES` (API 33+) | Read photos for the timeline and albums | First gallery launch | Explains why and shows a retry / settings button; nothing else loads |
| `READ_MEDIA_VIDEO` (API 33+) | Read videos | First gallery launch | Same as above |
| `READ_MEDIA_VISUAL_USER_SELECTED` (API 34+) | Android 14 "selected photos only" access | First gallery launch | Shows only what the user picked |
| `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | Media access on Android 12 and below | First gallery launch | Same as the media denial |
| `USE_BIOMETRIC` (API 28+) | Vault unlock | Vault unlock | Falls back to the PIN |
| `USE_FINGERPRINT` (`maxSdkVersion=28`) | Older fingerprint API; pulled in by `androidx.biometric` | Vault unlock | Falls back to the PIN |
| `CAMERA` (`required="false"`) | Scan the pairing QR code on the transfer screen only | First scan | The user types the pairing code instead |
| `INTERNET` | Local transfer only. Android needs it for any socket. Narrowed by `LocalAddressRules` | Install time | — |
| `ACCESS_WIFI_STATE` | Read the phone's own Wi-Fi address to bind the listener and build the pairing code. Not a connectivity check | Install time | — |
| `ACCESS_NETWORK_STATE` | Declared with the transfer permissions. No app code calls `ConnectivityManager`; the need for it is not written down in the manifest — see §17 | Install time | — |
| `CHANGE_WIFI_STATE` | Offer a scanned Wi-Fi code to Android as a network *suggestion*, on the in-image scanner screen only. The app never joins a network itself | Install time | Falls back to opening Wi-Fi settings |

Permission review rules:

- Request only what the app uses. Remove anything unused at once.
- Dangerous permissions are asked for at the point of use, with a reason, never at start-up.
- The app keeps working in a reduced but safe way if a permission is denied.
- Adding any permission means updating this table, `CLAUDE.md`, `AGENTS.md` and the release
  check in [release_process.md](release_process.md) §6.
- The user can read this table in the app: **Settings → Permissions** lists every permission
  above, the merged-only receiver permission, and the three removed ones, each with its reason.
  The list lives in `lib/core/constants/app_permissions.dart`.
  `test/core/constants/app_permissions_test.dart` fails if it no longer matches the manifest, so
  adding a permission also means adding its row and its text in all three languages.

---

## 12. OWASP Mobile Top 10 Compliance

| ID | Risk | Control | Status |
|---|---|---|---|
| M1 | Improper Credential Usage | Keystore-held vault key; PIN stored as a PBKDF2 hash; no hard-coded secrets | verified |
| M2 | Inadequate Supply Chain Security | `pubspec.lock` committed; open-source packages only; HTTP clients, cloud SDKs, analytics and crash reporting blocked, including as transitive dependencies ([dependencies.md](dependencies.md)). `http` came in through `package_info_plus` until 2026-09-26; that plugin was replaced by the `app_info` channel and `pubspec.lock` now has no HTTP client | verified |
| M3 | Insecure Authentication | BiometricPrompt + PIN; vault locks on background and idle | verified |
| M4 | Insufficient Input/Output Validation | Parameterized SQL; scheme allow-list for intents; size limits on PDFs, frames and files; decoders with fallbacks | verified |
| M5 | Insecure Communication | No remote network. Local transfer only, to private addresses, AES-256-GCM per frame with an HMAC handshake (§19). `INTERNET` is present for this reason | verified |
| M6 | Inadequate Privacy Controls | No telemetry; sensitive `toString()` redaction; EXIF privacy stripping; shredding | verified |
| M7 | Insufficient Binary Protections | `--obfuscate`, `--split-debug-info`, R8 | verified |
| M8 | Security Misconfiguration | `allowBackup="false"`, `dataExtractionRules` for cloud backup and device transfer, release not debuggable, 12-permission check | verified |
| M9 | Insecure Data Storage | Vault encrypted; `SharedPreferences` holds only the language; vault metadata is plain text in the private DB | risk-accepted — see §17 |
| M10 | Insufficient Cryptography | AES-256-GCM, random IVs, PBKDF2 with stored iteration counts, versioned formats | verified |

**M9 risk acceptance:** vault file names and notes sit in the app-private database without
encryption. They cannot be read by other apps and are never backed up by Android. They could be
read on a rooted device, which is out of scope (§3). Owner: the app developer. Revisit in §17.

---

## 13. Data Retention And Purge Policy

### Retention Schedule

| Data Type | Retention | Deletion Trigger |
|---|---|---|
| Media index, tags, albums, notes | Until the user deletes them | User action; app uninstall |
| Trash | Until the user empties it or restores | User action |
| Vault files and records | Until the user removes them from the vault | User action (shredded); uninstall |
| Transfer staging files | One transfer | Deleted on failure; leftovers swept when the transfer screen next opens |
| Backup / restore staging files | One operation | Deleted in a `finally` block |
| PDF extraction copy | One extraction | Deleted in a `finally` block |
| Thumbnail cache | App cache | OS may clear it; rebuilt on demand |
| Log files | `N/A` — none are written | — |

### Purge Implementation

- There is **no single "Delete all data" action** yet. Android's "Clear storage" in app settings
  removes the database, files and secure storage. Tracked in §17.
- Temporary files are app-private and deleted in the same session; leftovers are swept on the
  next open of the owning screen.

### Data Purge On Uninstall

- Android deletes all app data on uninstall. With backup off and the extraction rules in §10,
  nothing is restored on reinstall. Keystore keys are removed with the app.

---

## 14. Backup, Import, Export, And Recovery

- **Backup supported:** yes, `.gallerybak`.
- **Backup format:** encrypted only. There is no plain-text export of the library.
- **Import supported:** yes, restore from `.gallerybak`.
- **Recovery flow:** none for a lost backup password or vault PIN — by design. The create dialog
  says so.
- **Plain-text export policy:** media export (convert, PDF, share) creates new files the user
  chose to make. Vault items are never exported in the clear.

### 14.1 What the archive holds

Tags, virtual albums, album membership, favourites, user notes, place names and coordinates.
**Not photo or video bytes**: an archive that carried the media would be slow to write,
unwieldy to move, and largely redundant beside the transfer feature. Vaulted and trashed rows
are excluded entirely.

### 14.2 Container layout

```text
 offset  size  field
 0       4     magic, the ASCII bytes "GBAK"
 4       1     format version
 5       1     salt length
 6       n     PBKDF2 salt
 6+n     4     PBKDF2 iteration count, big-endian
 10+n    1     IV length
 11+n    m     AES-GCM initialisation vector
 11+n+m  ...   AES-256-GCM ciphertext of the gzipped JSON body, tag appended
```

### 14.3 Why the header is authenticated rather than encrypted

The salt and iteration count must be readable without the password, because they are what the
password is stretched with. They must not be *changeable*: an attacker who could rewrite the
iteration count down to 1 would turn a strong password into a weak one. The whole header is
therefore passed to AES-GCM as additional authenticated data. Changing any byte of the magic,
version, salt, count or IV makes the tag check fail and the archive refuse to open.

Nothing about the library is in the clear — the item counts and the creation date live inside
the encrypted body, because how many photos somebody has is itself worth not leaking.

### 14.4 Key derivation

PBKDF2-HMAC-SHA256, 210 000 iterations, 16-byte random per-file salt, 256-bit output. This is
higher than the vault's PIN count because an archive leaves the device and can be attacked at
leisure, and because it is derived once per backup rather than on every unlock.

The password is used and dropped. It is never stored, never logged, and there is no recovery
path; the create dialog says so plainly. A failed tag check is reported as "wrong password or
damaged file", because with GCM the two look the same from the inside and the user is owed both
possibilities.

### 14.5 Restore safety

A restore **only adds and updates**. `RestorePlan` has no delete list at all:

- a tag, album or media row on this device that the archive lacks is left untouched;
- a note or place already on the device is never replaced by an older one from the file;
- a favourite is set by the archive but never cleared by it;
- a record whose file is not on this device is reported as unmatched and dropped — no media row
  is ever invented for a photo that is not there.

The full plan, with counts, is shown to the user before a single row is written. Restoring
twice, or by mistake, cannot lose anything.

### 14.6 Storage access

The destination and the source are both chosen through the Storage Access Framework
(`ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`). No storage permission is requested and none
is held afterwards; the read grant is deliberately not persisted. Staging files holding the
archive in the clear are app-private and deleted in a `finally` block, so an interrupted backup
or restore leaves no readable copy behind.

---

## 15. Security Testing Strategy

| Area | Test Type | Notes |
|---|---|---|
| Crypto formats | Unit | Vault and backup round trips; header tamper must fail |
| Secret storage | Unit | Credential store fakes; PIN never stored |
| Lock / auth flow | Unit | `VaultLockPolicy` for every lifecycle state and the idle timeout |
| Backup and recovery | Unit | Serializer, merge plan (adds/updates only), wrong-password path |
| Local-network guard | Unit | `test/services/sync/local_address_rules_test.dart` — must refuse every public address |
| Scan schemes | Unit | Allow-list; refuse `intent:`, `javascript:`, embedded schemes and newlines |
| PDF extractor | Unit | Limits and malformed files |
| Data purge | `N/A` — no purge action yet (§13) | |
| Obfuscation, debuggable, permissions | Release build check | [release_process.md](release_process.md) §6 |

### Required Test Vectors Or Regression Areas

- Backup header: change any byte → refuses to open.
- Database migration v1 → v2 → v3.
- `LocalAddressRules`: every private range accepted; public IPv4, IPv6, hostnames, loopback as a
  peer, leading-zero octets and malformed input refused.
- Transfer: a file whose length or SHA-256 does not match is deleted, not saved.

---

## 16. Incident Response Notes

- **Triage owner:** the app developer.
- **Severity model:** *critical* — any data leaves the device without the user's pairing, or
  vault content is readable without unlock; *high* — a hostile file or code can crash the app or
  launch an intent outside the allow-list; *normal* — everything else.
- **Immediate containment:**
  - Stop distributing the affected version.
  - Ship a hotfix through [release_process.md](release_process.md).
- **User communication trigger:** any critical issue, through the store listing and release
  notes.
- **Patch release process:** [release_process.md](release_process.md) §13.

---

## 17. Open Risks And Future Hardening

- **Risk:** vault metadata (original file name, notes, tags) is plain text in the database.
  **Hardening option:** encrypt those columns with the vault key.
- **Risk:** no "Delete all data" action in the app.
  **Hardening option:** add one in Settings that clears the database, files, cache and secure
  storage.
- **Risk:** a future change passes a file name or path in a log *message* (only the `error`
  object is redacted automatically).
  **Hardening option:** review log calls in every change; the rule is in `AppLogger`'s doc
  comment and in CLAUDE.md.
- **Risk:** a dependency update adds a permission or network code.
  **Hardening option:** the 12-permission release check (§11) and the dependency checklist.
- **Risk:** `ACCESS_NETWORK_STATE` has no written reason and no direct caller in app code.
  **Hardening option:** find out whether a plugin needs it; either write the reason beside it
  in the manifest or remove it.

---

## 18. Security Review Checklist

Complete before every production release.

- [ ] Threat model reviewed and current.
- [ ] Sensitive data inventory updated.
- [ ] Logging reviewed — no new log line exposes personal data.
- [ ] Storage and backup behavior reviewed.
- [ ] Merged manifest has exactly the 11 permissions in §11 plus AndroidX's private
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` — no more, no fewer.
- [ ] `test/services/sync/local_address_rules_test.dart` passes.
- [ ] `--obfuscate` in every release build command.
- [ ] Debug symbols archived for this version.
- [ ] `android:debuggable` false in the merged release manifest.
- [ ] R8 / ProGuard rules checked.
- [ ] OWASP table (§12) reviewed and signed off.
- [ ] Retention and purge paths (§13) reviewed.
- [ ] Backup, restore and migration paths tested.
- [ ] `FLAG_SECURE` checked on all vault screens.
- [ ] Tests cover the highest-risk failure modes (§15).

---

## 19. Local Peer-to-Peer Transfer

### 19.1 Why `INTERNET` is present

Android requires `android.permission.INTERNET` for **any** socket, including one that only ever
reaches another phone on the same Wi-Fi router. A feature that transfers files device to device
cannot avoid it, and its presence says nothing on its own about where the app connects.

What bounds it is code, not the manifest:

| Guarantee | Where it is enforced |
|---|---|
| No connection to an address outside `10/8`, `172.16/12`, `192.168/16`, `169.254/16` | `LocalAddressRules`, applied in `PairingCodec.decode`, `P2pClientService.connect`, and `P2pServerService._onConnection` |
| The listener never binds to `0.0.0.0` | `P2pServerService.start` refuses the unspecified address outright |
| The listener exists only while the transfer screen is open | `SyncReceiveScreen` starts it in `initState` and stops it in `dispose`, on `AppLifecycleState.paused`, and on every failure path |
| Exactly one peer per session | `P2pServerService` closes the listener as soon as a peer completes the handshake |
| No HTTP client anywhere in the tree | [dependencies.md](dependencies.md) blocked list, checked before any package is added |

`test/services/sync/local_address_rules_test.dart` checks that every private range is accepted
and that public addresses, IPv6 forms, hostnames, loopback-as-a-peer, leading-zero octets and
malformed input are all refused. If that test ever passes a public address, the app's privacy
promise is broken.

### 19.2 Pairing and session keys

The pairing code carries a random 9-byte **pairing secret**, drawn from `SecureRandom` on the
Android side. Both devices stretch it into the 32-byte AES key with
`HMAC-SHA256(secret, "imgvidgal-session-v<version>")`, so the QR code and the typed fallback code
end at exactly the same key and neither route is the weaker one.

The secret exists for one session. It is never written to disk, never logged, and
`PairingPayload.toString` deliberately hides it.

### 19.3 Handshake

1. The connecting device sends a random 32-byte challenge.
2. The listening device answers with
   `HMAC-SHA256(sessionKey, "imgvidgal-pair-v<version>:" + challenge)`, proving it holds the key
   without sending it, plus its own protocol version.
3. The connecting device checks that answer in constant time and refuses the session if it does
   not match. That is how it knows it reached the phone whose code it scanned, not something
   squatting on the port.
4. Every frame after that is AES-256-GCM encrypted under the session key, so the connecting
   device proves it holds the key too: a peer without the key cannot make a frame that passes
   the tag check.

A device on the same Wi-Fi that never saw the pairing code can open a socket and gets no
further.

### 19.4 Wire format and limits

Frames are a 4-byte big-endian length, a 1-byte type, then the body. Each encrypted body is a
fresh 12-byte IV followed by the ciphertext and its 128-bit tag; an IV is never reused under a
key.

| Limit | Value | Why |
|---|---|---|
| Frame body | 2 MB | Checked against the *announced* length before any body is read, so a hostile peer cannot name an allocation size |
| Single file | 4 GB | Refused before the transfer is agreed to |
| Files per transfer | 2000 | Refused on both sides |
| Pairing window | 180 s | The listener closes itself if nobody connects |
| Idle timeout | 60 s | A connected socket that nothing crosses is closed |

### 19.5 What happens to an arriving file

Nothing reaches the gallery on the sender's word. Every incoming file is:

1. staged in an app-private directory, never in shared storage;
2. checked against the exact byte length its manifest entry promised;
3. checked against the SHA-256 that entry promised;
4. renamed through `TransferExchangeService.safeFileName`, which strips directory separators,
   parent references, leading dots and control characters, so a peer offering
   `../../etc/passwd` gets a plain file name;
5. published through MediaStore with `IS_PENDING` set until the bytes are all written, so no
   other app ever sees a half-copied photo.

A file that fails any check is deleted and reported, never saved. Staging files a crash left
behind are swept when the transfer screen next opens.

---

## 20. In-Image Scanner, OCR, Notes and PDF Tools

Phase 12 added four features that read something out of a file. None of them reaches a network,
and each one takes untrusted input, so each has a gate written down here.

### 20.1 A scanned code is untrusted input

A QR code came off a poster, a screenshot, or a stranger. It is exactly as trustworthy as a link
in an unsolicited message, and the one truly dangerous thing an app can do with it is hand it to
another app as an intent.

So the rule is a **permitted list of schemes, never a forbidden one**:

`http`, `https`, `tel`, `mailto`, `sms`, `geo`

Anything else — `javascript:`, `file:`, `content:`, `intent:`, `data:`, `jar:` and every scheme
nobody has thought of yet — is shown as plain text and never launched. The list lives in
`AppConstants.scanLaunchableSchemes`, is enforced by `ScanActionResolver` in Dart, and enforced
again by `IntentChannelHandler.ALLOWED_SCHEMES` in Kotlin. Neither side trusts the other. The
Kotlin side builds `ACTION_VIEW` with an explicit `Uri` and never uses `Intent.parseUri`, which
would accept the `intent:` form and let a printed square name the component it lands in.

A value that carries its own scheme, a newline, or a `://` inside it is refused rather than
encoded, because that shape is how an injected intent would try to get through.

Adding a scheme to that list is a security change, not a convenience. It needs a reason written
beside it and a matching `<queries>` entry in the manifest.

### 20.2 Wi-Fi codes

A `WIFI:` code is parsed into an SSID, a security type and a password. The password is never
shown on screen, never written to a log, and never included in any `toString`. Only the network
name appears.

Joining is a **suggestion**, not an action: on Android 10 and above the app calls
`addNetworkSuggestions` and opens the Wi-Fi panel, and the user taps the network themselves.
Below that, and whenever Android refuses the suggestion, the app opens the Wi-Fi settings and
copies the password so the user can paste it. **The app never silently joins a network**, which
matters when the code was stuck to a wall in a cafe.

The password is put on the clipboard marked `EXTRA_IS_SENSITIVE`, so Android 13 and above leaves
it out of the clipboard preview that pops up on screen.

### 20.3 Text read out of a photo

OCR runs entirely on the device. The language files ship in `assets/tessdata/` and are never
downloaded; the plugin's README shows a network fetch helper, and that code is not used. Text
pulled out of a photo can be a payslip, a prescription or a letter, so:

- it is never logged, in any build — `OcrResult.toString()` reports a character count and the
  language, never the text;
- it is never written anywhere on its own. The user copies it, or chooses to put it in that
  photo's notes. Nothing is saved without a tap.

### 20.4 Notes

A note is private writing about a private photo. `MediaNote.toString()` reports a length, never
the text. Notes are stored in the media row's `user_notes` column, inside the app's own
database, and travel only where the media row already travels: an encrypted backup, or a
transfer the user paired by hand.

A link inside a note is checked with the same scheme rule as a scanned code, because a note can
hold text pasted in from one. A link the app will not open is not underlined and does not look
tappable.

### 20.5 A PDF is untrusted input

The extractor is pure Dart and refuses before it allocates:

| Guard | Value |
|---|---|
| Largest file opened | 256 MB, checked while copying, not after |
| Largest number of images read | 500 |
| Largest declared image | 80 million pixels |
| Largest single decoded stream | 128 MB |

A width and height are a *claim* made by the file, so they are checked before a byte is
allocated for them. Nothing in the lexer throws: a malformed, truncated or hostile file comes
back as a refusal, and an object that will not decode comes back listed with a reason (hard
rule 5).

An encrypted PDF is **refused rather than opened**. Most encrypted PDFs in the wild use an empty
owner password and could technically be read, but doing that quietly would be the app deciding
on the user's behalf that a lock does not count.

The chosen PDF is copied into app-private cache to be read, and that copy is deleted in a
`finally` block, so an interrupted extraction leaves no copy of the user's document inside the
app. Both the source and the destination go through the Storage Access Framework and
MediaStore, so the tool holds no storage permission. Extracted pictures are new files written
under fresh names; nothing is ever overwritten (hard rule 4).

### 20.6 What these features do not touch

The vault is out of scope for the scanner and for OCR. Vault media decrypts to memory only, and
both readers need a file path; writing a plaintext copy out to disk so a decoder could open it
would undo what §6 is for. The viewer offers neither tool on a vault item.
