# Security — Image & Video Gallery

This document outlines the security architecture, threat model, cryptographic design, storage isolation, permission controls, and privacy guarantees for the Image & Video Gallery application. Read this before modifying any storage, cryptography, vault, permission, or backup logic.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [architecture.md](architecture.md)
- [guidelines/security.md](guidelines/security.md)

---

## 1. Security Scope

- **Application**: Image & Video Gallery
- **Data Sensitivity Level**: High (private personal photos, videos, biometric authentication, encrypted vault data).
- **Target Platform**: Android (minSdk 24, targetSdk 35).
- **Profiles Applied**: Core Baseline + Sensitive Data Extension + Local-Network-Only Profile.

---

## 2. Security Objectives

1. **Local-Network-Only Guarantee**: The app never contacts a remote server. No HTTP client, no cloud backend, no analytics, no telemetry, no update check. `android.permission.INTERNET` exists for the peer-to-peer transfer feature alone, which opens a socket only to another device on the same local Wi-Fi network. No media, metadata, or diagnostics ever reach anywhere the user did not pair with by hand. See §10, *Local Peer-to-Peer Transfer*.
2. **Hardware-Backed Private Vault**: Protect private media using hardware-backed AES-256-GCM encryption with Android Keystore.
3. **Anti-Forensic Media Shredding**: Overwrite sensitive media files with zeroes/random data before deletion to prevent file recovery.
4. **Window & Visual Protection**: Enforce `FLAG_SECURE` to block OS screenshots, screen recording, and app switcher visual sniffing on private screens.
5. **Safe & Non-Destructive File Operations**: Prevent media corruption or accidental overwrites through atomic staging files (`AtomicSaver`).

---

## 3. Threat Model Summary

### In-Scope Threats
- **Physical Device Theft / Unauthorized Casual Inspection**: Protection of private media via biometric/PIN-gated AES-256-GCM encrypted vault.
- **Accidental Exfiltration / Network Leaks**: Prevented structurally by omitting `android.permission.INTERNET` and prohibiting all HTTP/networking packages.
- **Third-Party App Snooping**: Vault media stored in app-private encrypted directories, completely isolated from public Android MediaStore indexing.
- **File Recovery After Deletion**: Mitigated by multi-pass zero-fill overwrite shredding before unlinking media files.
- **Visual Capture / Screen Recording**: Mitigated by native `FLAG_SECURE` window protection.
- **Log Leakage**: Strict logging policy; secrets, media byte arrays, and personal metadata are never logged.

### Out-of-Scope Threats
- Fully compromised/rooted Android devices with kernel-level memory inspection tools.
- Hardware physical extraction with electron microscopes or side-channel laboratory attacks.
- Malicious operating system versions or backdoored custom ROMs.

---

## 4. Sensitive Data Inventory

| Data Type | Content Example | Location | Protection Mechanism |
|---|---|---|---|
| **Vault Media** | Private photos & videos | App-private storage | Hardware-backed AES-256-GCM encrypted files |
| **Vault Encryption Key** | 256-bit symmetric key | Android Keystore | Hardware Security Module (HSM) / StrongBox |
| **Vault Metadata** | File names, tags, sizes | `sqflite` database | Encrypted fields / isolated DB records |
| **User Biometric State** | Fingerprint / Face auth | Android OS | Delegated to `local_auth` / Android BiometricPrompt |
| **Media Notes** | Private markdown notes | `sqflite` database | Local storage, zero network access |
| **Backup Archive** | `.gallerybak` files | User-selected destination | Password-derived AES-256-GCM encrypted archive |

---

## 5. Cryptography & Vault Design

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

### 5.1 Android Keystore Master Key
- Keys are generated inside the Android Keystore using `KeyGenParameterSpec` with `PURPOSE_ENCRYPT | PURPOSE_DECRYPT`.
- Hardware-backed storage (`KeyProperties.PURPOSE_ENCRYPT`) ensures keys cannot be extracted from device memory.

### 5.2 Encryption Standard (AES-256-GCM)
- Authenticated encryption using **AES-256-GCM** (Galois/Counter Mode).
- Every encrypted file has a freshly generated cryptographically secure 96-bit Initialization Vector (IV).
- 128-bit authentication tags prevent tampering or ciphertext corruption.

### 5.3 Anti-Forensic File Shredding
- Before moving files into the vault or permanently deleting sensitive media:
  1. Open file with random access write mode.
  2. Overwrite entire file payload with zeroes (`0x00`).
  3. Overwrite entire file payload with cryptographically random bytes.
  4. Flush storage buffers to physical disk (`sync`).
  5. Delete file link from filesystem.

### 5.4 Zero Cache Leaks
- Vault media thumbnails are generated on-the-fly and kept in encrypted/transient memory only.
- No decrypted vault frames or thumbnails are ever written to public cache or `getTemporaryDirectory()`.

---

## 6. Access Control & Inactivity Protections

- **Authentication**: Android BiometricPrompt (Fingerprint / Face Unlock) with PIN / Passcode fallback.
- **Inactivity Timeout**: Configurable auto-lock after 30 seconds, 1 minute, or 5 minutes of inactivity.
- **Background Auto-Lock**: Vault immediately locks and clears decrypted memory buffers when `AppLifecycleState` transitions to `paused` or `inactive`.
- **`FLAG_SECURE` Native Window**: Window flag active when viewing the vault or media viewer to prevent screenshotting and thumbnail capture in Android's recent task switcher.

---

## 7. Platform Permissions & Scoped Storage

| Permission | Android Level | Justification | Point of Use |
|---|---|---|---|
| `READ_MEDIA_IMAGES` | API 33+ | Query device photos for timeline and albums | Requested on first gallery launch |
| `READ_MEDIA_VIDEO` | API 33+ | Query device videos for timeline and player | Requested on first gallery launch |
| `READ_EXTERNAL_STORAGE` | API 24–32 | Legacy access to device media on older Android versions | Requested on first gallery launch |
| `USE_BIOMETRIC` | API 28+ | Authenticate user for Secure Vault unlock | Point of vault access |
| `USE_FINGERPRINT` | API 24–28 | The older fingerprint permission, for devices below API 28; pulled in by `androidx.biometric` and declared explicitly | Point of vault access |
| `android.permission.INTERNET` | **PRESENT** | Local peer-to-peer transfer only. Android requires it for any socket, including a LAN-only one. Narrowed in code by `LocalAddressRules`. | Install-time, no prompt |
| `android.permission.ACCESS_WIFI_STATE` | **PRESENT** | Reads the device's own Wi-Fi address so the listener can bind to it and show it in the pairing code. Not a connectivity check. | Install-time, no prompt |
| `android.permission.CHANGE_WIFI_STATE` | **PRESENT** | Offering a scanned Wi-Fi code to Android as a network suggestion, on the in-image scanner screen and nowhere else. A suggestion is the strongest thing an app may do here without holding location permission, and Android still makes the user pick the network by hand. The app never joins a network on its own. | Install-time, no prompt |
| `android.permission.CAMERA` | **PRESENT** | Reading the pairing QR code on the transfer screen, and nowhere else. Declared `required="false"`, so a device with no camera can still pair by typing the code. | Runtime, on first scan |

---

## 8. OWASP Mobile Top 10 Compliance Matrix

| ID | Risk | Mitigation in Image & Video Gallery | Status |
|---|---|---|---|
| **M1** | Improper Credential Usage | Hardware-backed Android Keystore; zero hardcoded secrets | **Verified** |
| **M2** | Inadequate Supply Chain | Verified open-source packages only. HTTP clients, cloud SDKs, analytics and crash reporting stay blocked; the only networking is `dart:io` sockets used by the transfer feature | **Verified** |
| **M3** | Insecure Authentication | BiometricPrompt + PIN fallback; auto-lock on app background | **Verified** |
| **M4** | Insufficient Input Validation | Parameterized SQLite queries; resilient media decoders with fallbacks | **Verified** |
| **M5** | Insecure Communication | Zero network calls; `INTERNET` permission absent from manifest | **Verified** |
| **M6** | Inadequate Privacy Controls | Anti-forensic shredding, EXIF scrubber, zero cache leaks | **Verified** |
| **M7** | Insufficient Binary Protections | `--obfuscate`, `--split-debug-info`, R8/ProGuard shrinking | **Verified** |
| **M8** | Security Misconfiguration | `android:allowBackup="false"`, `android:debuggable="false"` | **Verified** |
| **M9** | Insecure Data Storage | AES-256-GCM encrypted vault; no sensitive data in SharedPreferences | **Verified** |
| **M10** | Insufficient Cryptography | Authenticated AES-256-GCM; random 96-bit IV per file | **Verified** |

---

## 9. Binary Hardening & Build Verification

All production release builds must enforce:
1. **Dart Obfuscation**: `--obfuscate --split-debug-info=build/symbols/android-prod-<version>/`
2. **ProGuard / R8 Shrinking**: Shrinking and obfuscation enabled in `android/app/build.gradle.kts`.
3. **Debuggable Check**: Verify `android:debuggable="false"` in the merged release manifest.
4. **Manifest Permission Check**: Verify the merged release manifest declares exactly `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE` (maxSdkVersion 32), `USE_BIOMETRIC`, `USE_FINGERPRINT` (maxSdkVersion 28), `CAMERA`, `INTERNET`, `ACCESS_WIFI_STATE` and `ACCESS_NETWORK_STATE` — and nothing else. In particular `WAKE_LOCK` must still be removed by the merge, and no permission ExoPlayer or any other dependency introduces may appear unlisted.
5. **Local-Network Guard Check**: Verify `test/services/sync/local_address_rules_test.dart` passes. It is the test that fails if the transfer feature ever accepts an address off the local network, and a release must not ship without it green.

---

## 10. Local Peer-to-Peer Transfer

### 10.1 Why `INTERNET` is present

Android requires `android.permission.INTERNET` for **any** socket, including one that only ever reaches another phone on the same Wi-Fi router. The permission therefore cannot be avoided by a feature that transfers files device to device, and its presence says nothing on its own about where the app connects.

What bounds it is code, not the manifest:

| Guarantee | Where it is enforced |
|---|---|
| No connection to an address outside `10/8`, `172.16/12`, `192.168/16`, `169.254/16` | `LocalAddressRules`, applied in `PairingCodec.decode`, `P2pClientService.connect`, and `P2pServerService._onConnection` |
| The listener never binds to `0.0.0.0` | `P2pServerService.start` refuses the unspecified address outright |
| The listener exists only while the transfer screen is open | `SyncReceiveScreen` starts it in `initState` and stops it in `dispose`, on `AppLifecycleState.paused`, and on every failure path |
| Exactly one peer per session | `P2pServerService` closes the listener as soon as a peer completes the handshake |
| No HTTP client anywhere in the tree | `docs/dependencies.md` blocked list, checked before any package is added |

`test/services/sync/local_address_rules_test.dart` asserts every one of the private ranges is accepted and that public addresses, IPv6 forms, hostnames, loopback-as-a-peer, leading-zero octets and malformed input are all refused. If that test ever goes green on a public address, the app's privacy promise has been broken.

### 10.2 Pairing and session keys

The pairing code carries a random 9-byte **pairing secret**, drawn from `SecureRandom` on the Android side. Both devices stretch it into the 32-byte AES key with `HMAC-SHA256(secret, "imgvidgal-session-v<version>")`, so the QR code and the typed fallback code end at exactly the same key and neither route is the weaker one.

The secret exists for one session. It is never written to disk, never logged, and `PairingPayload.toString` deliberately hides it.

### 10.3 Handshake

1. The connecting device sends a random 32-byte challenge.
2. The listening device answers with `HMAC-SHA256(sessionKey, "imgvidgal-pair-v<version>:" + challenge)`, proving it holds the key without sending it, plus its own protocol version.
3. The connecting device verifies that answer in constant time and refuses the session if it does not match — which is how it knows it reached the phone whose code it scanned rather than something squatting on the port.
4. Every frame after that is AES-256-GCM encrypted under the session key, so the connecting device proves possession implicitly: a peer without the key cannot produce a frame that passes the tag check.

A device on the same Wi-Fi that never saw the pairing code can open a socket and gets no further.

### 10.4 Wire format and limits

Frames are a 4-byte big-endian length, a 1-byte type, then the body. Each encrypted body is a fresh 12-byte IV followed by the ciphertext and its 128-bit tag; an IV is never reused under a key.

| Limit | Value | Why |
|---|---|---|
| Frame body | 2 MB | Checked against the *announced* length before any body is read, so a hostile peer cannot name an allocation size |
| Single file | 4 GB | Refused before the transfer is agreed to |
| Files per transfer | 2000 | Refused on both sides |
| Pairing window | 180 s | The listener closes itself if nobody connects |
| Idle timeout | 60 s | A connected socket that nothing crosses is closed |

### 10.5 What happens to an arriving file

Nothing reaches the gallery on the sender's word. Every incoming file is:

1. staged in an app-private directory, never in shared storage;
2. checked against the exact byte length its manifest entry promised;
3. checked against the SHA-256 that entry promised;
4. renamed through `TransferExchangeService.safeFileName`, which strips directory separators, parent references, leading dots and control characters, so a peer offering `../../etc/passwd` gets a plain file name;
5. published through MediaStore with `IS_PENDING` set until the bytes are all written, so no other app ever sees a half-copied photo.

A file that fails any check is deleted and reported, never saved. Staging files a crash left behind are swept when the transfer screen next opens.

---

## 11. Backup Archive Format

### 11.1 What the archive holds

Tags, virtual albums, album membership, favourites, user notes, place names and coordinates. **Not photo or video bytes**: an archive that carried the media would be slow to write, unwieldy to move, and largely redundant beside the transfer feature. Vaulted and trashed rows are excluded entirely.

### 11.2 Container layout

```
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

### 11.3 Why the header is authenticated rather than encrypted

The salt and iteration count must be readable without the password, because they are what the password is stretched with. They must not be *changeable*: an attacker who could rewrite the iteration count down to 1 would turn a strong password into a weak one. The whole header is therefore passed to AES-GCM as additional authenticated data. Altering any byte of the magic, version, salt, count or IV makes the tag check fail and the archive refuse to open.

Nothing about the library is in the clear — the item counts and the creation date live inside the encrypted body, because how many photos somebody has is itself worth not leaking.

### 11.4 Key derivation

PBKDF2-HMAC-SHA256, 210 000 iterations, 16-byte random per-file salt, 256-bit output. Higher than the vault's PIN count because an archive leaves the device and can be attacked at leisure, and because it is derived once per backup rather than on every unlock.

The password is used and dropped. It is never stored, never logged, and there is no recovery path; the create dialog says so plainly. A failed tag check is reported as "wrong password or damaged file", because with GCM the two are indistinguishable from the inside and the user is owed both possibilities.

### 11.5 Restore safety

A restore **only adds and updates**. `RestorePlan` has no delete list at all:

- a tag, album or media row on this device that the archive lacks is left untouched;
- a note or place already on the device is never replaced by an older one from the file;
- a favourite is set by the archive but never cleared by it;
- a record whose file is not on this device is reported as unmatched and dropped — no media row is ever invented for a photo that is not there.

The full plan, with counts, is shown to the user before a single row is written. Restoring twice, or by mistake, cannot lose anything.

### 11.6 Storage access

The destination and the source are both chosen through the Storage Access Framework (`ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`). No storage permission is requested and none is held afterwards; the read grant is deliberately not persisted. Staging files holding the archive in the clear are app-private and deleted in a `finally` block, so an interrupted backup or restore leaves no readable copy behind.

---

## 12. In-Image Scanner, OCR, Notes and PDF Tools

Phase 12 added four features that read something out of a file. None of them reaches a
network, and each one takes untrusted input, so each has a gate written down here.

### 12.1 A scanned code is untrusted input

A QR code came off a poster, a screenshot, or a stranger. It is exactly as trustworthy as a
link in an unsolicited message, and the one genuinely dangerous thing an app can do with it
is hand it to another app as an intent.

So the rule is a **permitted list of schemes, never a forbidden one**:

`http`, `https`, `tel`, `mailto`, `sms`, `geo`

Anything else — `javascript:`, `file:`, `content:`, `intent:`, `data:`, `jar:` and every
scheme nobody has thought of yet — is shown as plain text and never launched. The list
lives in `AppConstants.scanLaunchableSchemes`, is enforced by `ScanActionResolver` in Dart,
and enforced again by `IntentChannelHandler.ALLOWED_SCHEMES` in Kotlin. Neither side trusts
the other. The Kotlin side builds `ACTION_VIEW` with an explicit `Uri` and never uses
`Intent.parseUri`, which would accept the `intent:` form and let a printed square name the
component it lands in.

A value that carries its own scheme, a newline, or a `://` inside it is refused rather than
encoded, because that shape is how an injected intent would try to get through.

Adding a scheme to that list is a security change, not a convenience. It needs a reason
written beside it and a matching `<queries>` entry in the manifest.

### 12.2 Wi-Fi codes

A `WIFI:` code is parsed into an SSID, a security type and a password. The password is
never shown on screen, never written to a log, and never included in any `toString`. Only
the network name appears.

Joining is a **suggestion**, not an action: on Android 10 and above the app calls
`addNetworkSuggestions` and opens the Wi-Fi panel, and the user taps the network
themselves. Below that, and whenever Android refuses the suggestion, the app opens the
Wi-Fi settings and copies the password so the user can paste it. **The app never silently
joins a network**, which matters when the code was stuck to a wall in a cafe.

The password is put on the clipboard marked `EXTRA_IS_SENSITIVE`, so Android 13 and above
leaves it out of the clipboard preview that pops up on screen.

### 12.3 Text read out of a photo

OCR runs entirely on the device. The language files ship in `assets/tessdata/` and are
never downloaded; the plugin's README shows a network fetch helper, and that code is not
used. Text pulled out of a photo can be a payslip, a prescription or a letter, so:

- it is never logged, in any build — `OcrResult.toString()` reports a character count and
  the language, never the text;
- it is never written anywhere on its own. The user copies it, or chooses to put it in that
  photo's notes. Nothing is saved without a tap.

### 12.4 Notes

A note is private writing about a private photo. `MediaNote.toString()` reports a length,
never the text. Notes are stored in the media row's `user_notes` column, inside the app's
own database, and travel only where the media row already travels: an encrypted backup, or
a transfer the user paired by hand.

A link inside a note is checked with the same scheme rule as a scanned code, because a note
can hold text pasted in from one. A link the app will not open is not underlined and does
not look tappable.

### 12.5 A PDF is untrusted input

The extractor is pure Dart and refuses before it allocates:

| Guard | Value |
|---|---|
| Largest file opened | 256 MB, checked while copying, not after |
| Largest number of images read | 500 |
| Largest declared image | 80 million pixels |
| Largest single decoded stream | 128 MB |

A width and height are a *claim* made by the file, so they are checked before a byte is
allocated for them. Nothing in the lexer throws: a malformed, truncated or hostile file
comes back as a refusal, and an object that will not decode comes back listed with a reason
(hard rule 5).

An encrypted PDF is **refused rather than opened**. Most encrypted PDFs in the wild use an
empty owner password and could technically be read, but doing that quietly would be the app
deciding on the user's behalf that a lock does not count.

The chosen PDF is copied into app-private cache to be read, and that copy is deleted in a
`finally` block, so an interrupted extraction leaves no copy of the user's document inside
the app. Both the source and the destination go through the Storage Access Framework and
MediaStore, so the tool holds no storage permission. Extracted pictures are new files
written under fresh names; nothing is ever overwritten (hard rule 4).

### 12.6 What these features do not touch

The vault is out of scope for the scanner and for OCR. Vault media decrypts to memory only,
and both readers need a file path; writing a plaintext copy out to disk so a decoder could
open it would undo what §5 is for. The viewer offers neither tool on a vault item.
