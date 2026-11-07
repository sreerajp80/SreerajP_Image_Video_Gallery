# Change log — Play screenshots, store icon and feature graphic

**Plan:** [plans/20261106_212915_play-screenshots-and-graphics.md](../plans/20261106_212915_play-screenshots-and-graphics.md)
**Date:** 2026-11-06

## What changed

| File | Change |
| --- | --- |
| `docs/images/screenshots/01_timeline.png` … `07_languages.png` | New. 7 English screenshots, 1080 × 1920, 24-bit PNG |
| `docs/images/feature_graphic.png` | New. 1024 × 500, no transparency |
| `play_closed_testing/graphics/app_icon_512.png` | New (local only). 512 × 512, drawn from the launcher vector |
| `play_closed_testing/screenshots/raw/*.png` | New (local only). Raw captures |
| `play_closed_testing/PUBLISHING_GUIDE.md`, `store_listing.md`, other Play docs | Screenshot list, graphics states, version now 2.6.4 (22) |

No app code, manifest, ARB or submodule file changed. The README was not changed.

## How it was done

- 36 made-up pictures (drawn by a script, no GPS or camera data) were pushed to the emulator,
  dated 2022–2026, three of them on 6 November of earlier years for "On This Day".
- The prod 2.6.4 (22) x86_64 APK was installed. The emulator screen was set to 1080 × 1920 with
  status-bar demo mode, and both were reset at the end.
- Test albums, one favourite and a test vault (random PIN, emulator only) were made in the app.

## Differences from the plan

- **7 screenshots, not 8.** The vault always blocks screenshots; its "Screenshots blocked" row is
  not a switch. Files were renumbered 01–07.
- **No Malayalam set yet.**
- **The icon was drawn by a Python script** (curves and arcs turned into polygons), not in the
  browser: headless Edge did not finish on this machine.
- **Version is 2.6.4 (22)**, not 2.6.3 (21); a newer build existed.
- The transfer screenshot is the start screen, which shows no network address, so nothing needed
  blurring.

## Found while capturing (not fixed; each needs its own plan)

1. **Viewer shows the wrong picture after the star is tapped.** Open any photo, tap the
   favourite star: the picture changes to another photo (the newest one), while the title still
   names the first. Seen three times, from both the timeline and On This Day.
2. **Album count and contents disagree.** An album card said "1 item", but the album opened
   empty and the card had no cover. The test album was deleted afterwards.
3. **On This Day tiles do not support long-press selection**, unlike timeline tiles. This may be
   on purpose.

A timeline error icon seen at the start went away without a rebuild; the owner confirmed it was
an emulator problem, not an app bug.
