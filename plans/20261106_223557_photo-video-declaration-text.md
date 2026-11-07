# Plan — Real Play text for the photo and video declaration

**Status:** completed

**Date:** 2026-11-06

## Issue

The real Play Console form has two boxes, "Read media images" and "Read media video", each limited
to 250 characters. `play_closed_testing/app_content_answers.md` §3 has one draft of about 430
characters, which does not fit.

## Files to change

| File | Change |
| --- | --- |
| `play_closed_testing/app_content_answers.md` | §3: replace the single long draft with the two answers (247 and 240 characters), and note the real form's fields and limit, as seen on 2026-11-06 |
| `change_log/<timestamp>_photo-video-declaration-text.md` | New change log |

## Fix

Write the two answers agreed in chat into §3, one per box, with their character counts. Keep the
partial-access note and the video-demo note as they are.

## Security impact

None. Text in a local, gitignored document only.
