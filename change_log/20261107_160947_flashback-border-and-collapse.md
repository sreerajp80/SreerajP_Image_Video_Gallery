# Change log — Make On This Day look different from the timeline

**Plan:** [plans/20261107_160051_flashback-border-and-collapse.md](../plans/20261107_160051_flashback-border-and-collapse.md)
**Date:** 2026-11-07

## Why

On This Day tiles do not support long press (on purpose, see
[plans/20261107_155244_flashback-long-press-select.md](../plans/20261107_155244_flashback-long-press-select.md)).
The section looked almost the same as the timeline, so that felt like a bug. Now the two areas
look clearly different.

## What changed

| File | Change |
| --- | --- |
| `lib/widgets/media/flashback_carousel.dart` | Section sits in a rounded box (radius 16) with a 1 dp `outlineVariant` border. New shaded title bar (`tertiaryContainer`) with icon, title, total photo count and an expand/collapse arrow. The whole bar is a button (`Semantics(button, expanded)`). The old `Divider` is gone. New `expanded` and `onToggle` parameters. |
| `lib/providers/timeline_providers.dart` | New `flashbackExpandedProvider` (`StateProvider<bool>`, default `false`, memory only). |
| `lib/widgets/timeline/timeline_body.dart` | Passes the open state and the toggle to the carousel. |
| `lib/widgets/media/timeline_date_header.dart` | Date header has a rounded `surfaceContainerHigh` shade. Height is still 48 dp. |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` | New keys `tooltipExpandFlashback`, `tooltipCollapseFlashback` (with `@` descriptions in English). |
| `lib/l10n/generated/*` | Regenerated with `flutter gen-l10n`. |
| `test/widgets/media/flashback_carousel_test.dart` | New: starts collapsed with count, tap opens and closes, border and title shade colours, empty list draws nothing. |
| `test/widgets/media/timeline_date_header_test.dart` | New test: shade present, header still fits 48 dp. |

## Differences from the plan

- The open-state provider went into `lib/providers/timeline_providers.dart`, not
  `memory_providers.dart`. That file is about low device memory (RAM), not "memories";
  `flashbackMemoriesProvider` already lives in `timeline_providers.dart`.
- The date header's padding changed (16/8 top/bottom to 8/4 outside the shade) so the shaded bar
  fits inside the same 48 dp row.

## Checks

- `flutter gen-l10n`, `dart format`, `flutter analyze`: clean.
- `flutter test`: all 2317 tests pass.
- **Not yet done:** a look on a real device or emulator (light and dark mode, all three languages,
  scrubber label after opening and closing the section).
- The new Sanskrit tooltips (`स्मृतीः दर्शय`, `स्मृतीः गोपय`) still need the owner's review.
