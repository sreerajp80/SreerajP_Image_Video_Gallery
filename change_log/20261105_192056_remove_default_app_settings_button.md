# Remove the "Open Android Settings" button from the Default Gallery screen

Implements: `plans/20261105_192056_remove_default_app_settings_button.md`

## Why

The button opened Android's "Default apps" page. Android has no "gallery" role, so
that page can never make this app the default gallery. The button misled users. The
only real way is the "Open with" chooser and "Always", which the screen already explains.

## What changed

- `lib/screens/settings/default_app_settings_screen.dart`: removed the button. The
  screen is now a `StatelessWidget` (no Riverpod needed). Added a doc comment that says
  why there is no button.
- `lib/services/intent/media_intent_service.dart`: removed `openDefaultAppsSettings()`.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`:
  removed the `openDefaultAppsSettings` channel case, its method, and the `canResolve`
  helper that only it used.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb`: removed the key
  `bodyDefaultAppOpenSettings`. Replaced the last line of `bodyDefaultAppDialog` with a
  true hint: clear the old app's default first (Settings → Apps → that app → Open by
  default). Generated files rebuilt with `flutter gen-l10n`.
- `test/screens/settings/settings_screen_test.dart`: the test now checks the
  instructions show and that there is no button.
- `test/services/intent/media_intent_service_test.dart`: removed the test for the
  deleted method.

## Checks

- `flutter gen-l10n`, `dart format` (no changes), `flutter analyze` (no issues),
  `flutter test` (all 2203 passed).
- The Kotlin change was not compiled in this change. The next Android build checks it.

## Open item

- The new Sanskrit line in `bodyDefaultAppDialog` needs the owner's review.

## Security impact

Small reduction only: one method-channel call that launched system settings screens is
gone. No permission, manifest, network or storage change.
