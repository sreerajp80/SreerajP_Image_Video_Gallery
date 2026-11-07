# Plan — On This Day tiles and long-press selection

**Status:** dropped

> Owner decided on 2026-11-07: keep as is (option B). The On This Day carousel is a small
> memories strip; tap opens the viewer, and long press is on purpose not used for selection.
> Selection stays a timeline and grid feature. No code change.

**Date:** 2026-11-07
**Found in:** [change_log/20261106_215251_play-screenshots-and-graphics.md](../change_log/20261106_215251_play-screenshots-and-graphics.md), bug 3

---

## 1. The issue

On the timeline, a long press on a photo tile starts selection mode. A long press on a tile in
the "On This Day" carousel does nothing.

Cause: `lib/widgets/media/flashback_carousel.dart` passes only `onTap` to its tiles. The timeline
(`lib/widgets/timeline/timeline_body.dart`) also passes `onLongPress` to `MediaGridTile`.

This may be on purpose. The carousel is a small "memories" strip, not a grid, so selecting from it
may not be wanted.

## 2. Open question for the owner (decide before this plan goes further)

Should a long press on an On This Day tile:

- **A.** start selection, the same as the timeline (photo selected in the main timeline), or
- **B.** stay as it is, and be written down as on purpose (then this plan is `dropped`)?

## 3. The fix (only if A)

To be filled in after the owner's answer. Likely: pass the timeline's `onItemLongPress` into
`FlashbackCarousel` and on to its tiles, and show the selected state on the carousel tile too.

## 4. Files to be changed (only if A)

| File | Change |
| --- | --- |
| `lib/widgets/media/flashback_carousel.dart` | Accept and use a long-press callback |
| `lib/widgets/timeline/timeline_body.dart` | Pass the callback in |
| `test/widgets/media/flashback_carousel_test.dart` | New or updated test |

## 5. Security impact

None. UI gesture only.
