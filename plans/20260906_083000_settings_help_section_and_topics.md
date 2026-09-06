# Help Section in Settings and Topic Help Pages

**Status:** completed

**Date:** 2026-09-06
**Implements:** Settings Help Section, Topic Cards, Help Detail Pages, and Settings About Section Organization

---

## 1. Context and Goals

The gallery application features an extensive suite of capabilities:
- Timeline, pinch grid (1-5 columns), date scrubber, and "On This Day" flashback memories.
- Media viewer with gestures, EXIF details, and hardware-accelerated video player.
- Non-destructive photo editor with crop, tone curves, filters, markup, redaction (blur, pixelate, blackout), and watermarking.
- Format converter (JPEG, PNG, WEBP, BMP), compression, video trimmer, frame grabber, and video-to-GIF converter.
- PDF multi-photo export and offline PDF image extraction.
- FTS5 full-text search with query prefixes (`tag:`, `type:`, `place:`, `camera:`, `before:`, `after:`) and 12-color tag management.
- Custom virtual albums (reorder, covers, pinning), device folder navigation, and smart auto-albums.
- Duplicate cleaner (SHA-256 exact match + pHash visual similarity, side-by-side comparison, and Best Photo recommendation).
- Secure private vault (AES-256-GCM encryption, biometric & PIN authentication, `FLAG_SECURE`, auto-lock, and secure shredding).
- Local P2P Wi-Fi transfer (QR code and manual pairing code, 100% local, zero internet).
- Password-protected encrypted backups (`.gbak`) and safe restore.
- Offline QR and barcode scanner with safe URL scheme filter, offline Malayalam & English OCR, and markdown notes.

All 1,793 existing tests pass and static analysis is completely clean.

The user requires:
1. Deep project analysis ensuring no errors, gaps, or conflicts across features (verified: existing features are solid, tested, and conflict-free).
2. A dedicated **Help section under Settings page**, where **each topic is presented as a card**, and tapping on any card opens that topic's help page.
3. Ensuring the **About screen** is prominently organized and accessible under Settings.

---

## 2. Proposed Changes

### 2.1 Help Topic Models & Content (`lib/models/help/help_topic.dart`)
- Define an immutable `HelpTopic` model representing a help topic with:
  - `id`: unique topic identifier.
  - `icon`: icon representing the feature.
  - `titleKey` / getter: localized title.
  - `summaryKey` / getter: localized one-sentence description.
  - `sections`: structured help items (Overview, How-To Steps, Tips & Shortcuts, Privacy & Offline Safeguards).
- Define the 12 core help topics covering all features of the gallery:
  1. `timeline`: Timeline & Memories
  2. `viewer`: Fullscreen Viewer & Video Player
  3. `editor`: Photo Editor & Markup
  4. `converter`: Format Conversion & Compression
  5. `pdf`: PDF Export & Image Extraction
  6. `search`: Search & Tagging
  7. `albums`: Albums & Folders
  8. `cleaner`: Duplicate Cleaner
  9. `vault`: Secure Private Vault
  10. `sync`: Local Wi-Fi Transfer
  11. `backup`: Backup & Restore
  12. `scanner`: QR Scanner & OCR

### 2.2 Help Topic Card Widget (`lib/widgets/help/help_topic_card.dart`)
- Material 3 `Card.outlined` for each topic:
  - Leading themed icon container.
  - Topic title in medium bold text.
  - Subtitle summarizing the topic.
  - Trailing chevron indicator (`Icons.chevron_right`).
  - Tappable with splash effect that navigates to the topic help page.

### 2.3 Help Topic Detail Screen (`lib/screens/help/help_topic_screen.dart`)
- AppBar with the topic title.
- Header hero card with feature icon, title, and "100% Offline" / security badge.
- Overview section explaining what the feature is and how it works.
- "How to Use" section with clean, numbered step-by-step guidance.
- "Tips & Shortcuts" section highlighting gestures, pro-tips, and shortcuts.
- "Privacy & Security" section detailing the offline guarantees for this feature.

### 2.4 Routing (`lib/core/routing/app_router.dart`)
- Add `kRouteHelpTopic = '$kRouteSettings/help/:topicId'`.
- Add helper method `String helpTopicPath(String topicId) => '$kRouteSettings/help/$topicId'`.
- Add GoRoute inside `settings` for `help/:topicId` mapping to `HelpTopicScreen`.

### 2.5 Settings Screen Update (`lib/screens/settings/settings_screen.dart`)
- Add a clear `_SectionHeader(title: l10n.help)` for the Help section.
- Render the topic cards in the Help section.
- Add an explicit `_SectionHeader(title: l10n.about)` before the About tile, ensuring the About screen is clearly identifiable and well-placed under Settings.

### 2.6 Localization (`lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb`)
- Add all localization strings for:
  - Help section headers and labels.
  - Titles, summaries, how-to steps, tips, and privacy descriptions for all 12 topics in both English and Malayalam.
- Run `flutter gen-l10n`.

### 2.7 Automated Tests
- Unit test for help topic definitions and content retrieval: `test/models/help/help_topic_test.dart`.
- Widget test for help cards and topic detail page: `test/screens/help/help_topic_screen_test.dart`.
- Update `test/widgets/settings/settings_screen_test.dart` to verify Help section rendering and navigation.

---

## 3. Files to be Created or Modified

### New Files
- `lib/models/help/help_topic.dart`
- `lib/widgets/help/help_topic_card.dart`
- `lib/screens/help/help_topic_screen.dart`
- `test/models/help/help_topic_test.dart`
- `test/screens/help/help_topic_screen_test.dart`

### Modified Files
- `lib/core/routing/app_router.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ml.arb`
- `test/widgets/settings/settings_screen_test.dart`

---

## 4. Verification Plan
- Run `flutter gen-l10n`.
- Run `dart format .`.
- Run `flutter analyze` to ensure 0 warnings/errors.
- Run `flutter test` to ensure all existing (1793) and new unit/widget tests pass.
