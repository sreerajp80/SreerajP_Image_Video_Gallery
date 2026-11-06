# Keep screen content above the system navigation bar

**Status:** completed

## What the issue is

On the Permissions screen the last button ("Open settings") is drawn under the
Android navigation bar (back / home / recents). The user cannot tap it well.

Why it happens:

- The app targets SDK 36. From Android 15, every app is drawn edge to edge:
  the app paints behind the status bar and the navigation bar.
- Flutter tells the app how tall those bars are through `MediaQuery.padding`.
- A `ListView` with **no** `padding:` adds this bottom space by itself. As soon
  as we give it our own `padding:` (for example `EdgeInsets.fromLTRB(16, 12, 16, 32)`),
  it **stops** adding the navigation-bar space. Our 32 px is less than the bar,
  so the last item sits under it.
- Screens that wrap the body in `SafeArea` (Backup, Albums, Trash, Timeline …)
  do not have this problem. The screens below do not.

## Screens checked

All 42 files in `lib/screens/` were checked.

**Already safe (no change):** album media, album reorder, albums, smart album,
backup, duplicate cleaner, duplicate compare, albums tab, folders tab, home
shell, PDF image extract, search, sync home / receive / send, tags, timeline,
trash, photo compare, about (adds the bottom inset itself), media viewer and
vault viewer (full-screen viewers; their bars already use `SafeArea`), image
editor (its tool bar already uses `SafeArea`).

**Affected — content or buttons can go under the navigation bar:**

| File | What is at the bottom |
|------|-----------------------|
| `lib/screens/settings/permissions_settings_screen.dart` | "Open settings" button (the screenshot) |
| `lib/screens/settings/settings_screen.dart` | last settings rows |
| `lib/screens/settings/appearance_settings_screen.dart` | last rows |
| `lib/screens/settings/default_app_settings_screen.dart` | last rows |
| `lib/screens/settings/developer_settings_screen.dart` | last rows |
| `lib/screens/settings/help_settings_screen.dart` | last help topics |
| `lib/screens/settings/language_settings_screen.dart` | last language option |
| `lib/screens/settings/privacy_settings_screen.dart` | last rows |
| `lib/screens/settings/safety_settings_screen.dart` | last rows |
| `lib/screens/help/help_topic_screen.dart` | end of help text |
| `lib/screens/ocr/extracted_text_screen.dart` | "Save to notes" / "Copy all" button row — worst case after Permissions |
| `lib/screens/notes/media_notes_screen.dart` | end of the note form |
| `lib/screens/scan/image_scan_screen.dart` | last scanned result |
| `lib/screens/vault/vault_gate_screen.dart` | unlock / set-up content when it scrolls |
| `lib/screens/vault/vault_settings_screen.dart` | last vault setting rows |
| `lib/screens/vault/vault_screen.dart` | last row of the vault grid |
| `lib/screens/convert/format_converter_screen.dart` | last options (list content; the FAB is already lifted by Scaffold) |
| `lib/screens/convert/pdf_export_screen.dart` | last options (same) |
| `lib/screens/video/video_tools_screen.dart` | last options in each tab (same) |

## Plan for the fix

Use the same pattern the safe screens already use, so the code stays consistent:

1. In each affected file, wrap the Scaffold `body:` in `SafeArea(...)`.
   - The AppBar already handles the top, so `SafeArea` adds space only at the
     bottom (and on the sides in landscape, where the navigation bar can sit).
   - For `vault_screen.dart` and `vault_settings_screen.dart` the body is built
     inside a `.when(...)`; wrap the whole `.when(...)` result once.
2. Do not change full-screen viewers (media viewer, vault viewer, photo compare);
   they are edge to edge on purpose and already handle their own bars.
3. Add a widget test `test/screens/settings/permissions_settings_screen_test.dart`
   that gives the screen a 48 px bottom system inset and checks that the
   "Open settings" button ends above that inset. This guards against the bug
   coming back.
4. Run `dart format .`, `flutter analyze` and `flutter test`.

No change to text, ARB files, permissions, storage or network.

## Files to be changed

- The 19 screen files in the "Affected" table above.
- New: `test/screens/settings/permissions_settings_screen_test.dart`.

**Security impact:** none — layout only.
