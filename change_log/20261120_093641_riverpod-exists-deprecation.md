# Change log — Replace deprecated `ref.exists` (Riverpod 3.5.0)

Implements plan: `plans/20261120_093641_riverpod-exists-deprecation.md`

## What changed

- `lib/providers/timeline_providers.dart` (`timelineItemsProvider`):
  `ref.exists(fullProvider)` → `ref.read(fullProvider.exists)`. Same behaviour:
  a one-time check, not a subscription, so the stream does not restart when the
  full list provider is created.

## Difference from the plan

None.

## Not done / not checked

- `flutter analyze` and `flutter test` are run by the owner.

## Security impact

None.
