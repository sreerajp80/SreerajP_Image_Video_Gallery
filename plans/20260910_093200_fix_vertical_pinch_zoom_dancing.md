# Fix vertical pinch-to-zoom causing image to "dance"

**Status:** Proposed

## Problem

When you pinch to zoom vertically on an image in the fullscreen viewer, the image jitters or "dances" instead of zooming smoothly. The root cause is a **gesture conflict between the dismiss-drag `Listener` and the `InteractiveViewer` zoom**.

### What happens

1. The `Listener` in `media_viewer_screen.dart` (line 529-532) sits **outside** `InteractiveViewer` and receives **every** pointer event — including both fingers of a pinch gesture.
2. When you pinch vertically (one finger moves down), `_onPointerMove` sees `dy > 0` on the first (or lower-moving) pointer and treats it as a swipe-down-to-dismiss. It calls `setState` to update `dismissOffset`, which translates and scales the **entire page** via `Transform.translate` and `Transform.scale` (lines 535–538).
3. At the same time, `InteractiveViewer` is also processing the same pointers as a zoom gesture.
4. The result is the image bouncing between two competing transforms every frame — the dismiss slide and the zoom scale — which appears as "dancing".

### Why it happens only on vertical pinch

A horizontal pinch keeps `dx > dy.abs()`, which the code already ignores (line 417). But a vertical pinch naturally has `dy > 0` on at least one finger, so the dismiss logic activates alongside the zoom.

## Proposed Changes

### Dismiss gesture guard

#### [MODIFY] `media_viewer_screen.dart`

The `Listener` needs to know the difference between a **single-finger downward drag** (dismiss) and a **multi-finger pinch** (zoom). The fix:

1. **Track the number of active pointers.** Add an `int _activePointers = 0` counter. Increment it on `onPointerDown`, decrement on `onPointerUp` and `onPointerCancel`.
2. **Block dismiss when two or more pointers are active.** In `_onPointerMove`, skip the dismiss logic when `_activePointers >= 2`. This means a two-finger pinch never triggers the dismiss slide, regardless of direction.
3. **Cancel an in-progress dismiss if a second finger lands.** If `_transform.isDismissing` and a second pointer arrives, reset `dismissOffset` to 0 immediately so the page snaps back.
4. **Handle `onPointerCancel`.** Add a handler that decrements the counter and resets the dismiss state, so a cancelled pointer does not leave the dismiss stuck.

No changes to `InteractiveImageView`, `ViewerTransformService`, or `ViewerTransform` are needed. The fix is entirely within the dismiss pointer handling in `_MediaViewerScreenState`.

## Verification Plan

### Manual Verification
- Open a photo in the fullscreen viewer.
- Pinch vertically (both fingers moving up/down) — the image should zoom smoothly with no jittering.
- Pinch diagonally and horizontally — same smooth zoom.
- Single-finger swipe down — dismiss should still work exactly as before.
- Single-finger swipe down, then add a second finger — dismiss should cancel and zoom should take over.
- Zoomed-in panning — should still work (dismiss is already disabled when zoomed).

### Automated Tests
```bash
flutter analyze
flutter test
```
