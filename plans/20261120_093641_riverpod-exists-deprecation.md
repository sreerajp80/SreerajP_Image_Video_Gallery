# Plan — Replace deprecated `ref.exists` (Riverpod 3.5.0)

**Status:** completed

## The issue

After the Flutter 3.50.1 upgrade, `pub get` moved `riverpod` and
`flutter_riverpod` from 3.4.3 to 3.5.0. Riverpod 3.5.0 deprecates
`Ref.exists(provider)`. `flutter analyze` now reports one `info`
(`deprecated_member_use`) at `lib/providers/timeline_providers.dart:114`.
The project rule is zero analyzer issues.

The replacement is the `exists` listenable on the provider itself. Note: the
deprecation message says `provider.exist`, but the real getter in 3.5.0 is
`exists`.

This is the only use of `ref.exists` in `lib/` and `test/`.

## The fix

In `timelineItemsProvider`:

```dart
// before
ref.exists(fullProvider) && ref.read(fullProvider).hasValue;
// after
ref.read(fullProvider.exists) && ref.read(fullProvider).hasValue;
```

`ref.read`, not `ref.watch`: the old call was a one-time check. Watching it would
rebuild this provider as soon as the next line creates `fullProvider`, which
would restart the stream and send the first page again.

## Files to change

- `lib/providers/timeline_providers.dart`

No test change: `test/providers/media_library_reload_test.dart` already covers
"first page on cold load, no first page on reload", which is exactly what this
line decides.

## How to check

`flutter analyze` (no issues) and `flutter test` (all pass), run by the owner.

## Security impact

None.
