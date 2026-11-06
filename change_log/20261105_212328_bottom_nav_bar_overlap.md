# Keep screen content above the system navigation bar

Implements plan: `plans/20261105_211700_bottom_nav_bar_overlap.md`

## What was wrong

On some screens the last item or button was drawn under the Android navigation
bar. The Permissions screen's "Open settings" button was one example. The app
targets SDK 36, so Android draws it edge to edge. A `ListView` that has its own
`padding:` does not add space for the navigation bar, and these screens had no
`SafeArea` to add it.

## What changed

The Scaffold `body:` is now wrapped in `SafeArea(...)` in these 19 screens:

- `lib/screens/settings/permissions_settings_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/settings/appearance_settings_screen.dart`
- `lib/screens/settings/default_app_settings_screen.dart`
- `lib/screens/settings/developer_settings_screen.dart`
- `lib/screens/settings/help_settings_screen.dart`
- `lib/screens/settings/language_settings_screen.dart`
- `lib/screens/settings/privacy_settings_screen.dart`
- `lib/screens/settings/safety_settings_screen.dart`
- `lib/screens/help/help_topic_screen.dart`
- `lib/screens/ocr/extracted_text_screen.dart`
- `lib/screens/notes/media_notes_screen.dart`
- `lib/screens/scan/image_scan_screen.dart`
- `lib/screens/vault/vault_gate_screen.dart`
- `lib/screens/vault/vault_settings_screen.dart` (both the main screen and the change-PIN screen)
- `lib/screens/vault/vault_screen.dart`
- `lib/screens/convert/format_converter_screen.dart`
- `lib/screens/convert/pdf_export_screen.dart`
- `lib/screens/video/video_tools_screen.dart`

Full-screen viewers (media viewer, vault viewer, photo compare) were left as
they are. They are edge to edge on purpose and already handle their own bars.

## Test

- Added the test "keeps the Open settings button above the navigation bar" to
  `test/screens/settings/settings_screen_test.dart`. It sets a phone-sized
  screen with a 48 px bottom bar, scrolls to the end and checks the button ends
  above the bar.
- Change from the plan: the plan named a new test file. The test went into the
  existing settings test file instead, so it can reuse that file's setup.
- Without the fix the test fails (button bottom 754, limit 752). With the fix it passes.

## Checks

- `dart format`: no changes needed.
- `flutter analyze`: no issues.
- `flutter test`: all 2225 tests pass.

Not yet checked on a real phone.
