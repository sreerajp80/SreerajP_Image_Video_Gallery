# Create a Beautiful App Icon for SreerajP Image Video Gallery

**Status:** completed

**Date:** 2026-09-06
**Implements:** Replace placeholder Android launcher icon with a custom, modern adaptive icon and monochrome themed icon

---

## 1. Context and Problem Statement

The app currently uses a basic placeholder launcher icon (`android/app/src/main/res/drawable/ic_launcher_foreground.xml`) with a flat white outline on a plain dark blue background. As noted in the existing code comment, this was a temporary placeholder.

The app needs a modern, polished icon that reflects its identity:
- **Offline-first Image and Video Gallery**
- Brand colors: Sapphire Blue / Deep Cyan (`#006688`), Sky Cyan (`#76D1FF`), Dark Sapphire (`#0B1E2E`), and Warm Golden Amber (`#FFB74D` / `#FFA000`)
- Visual theme: A stylized photo canvas with glowing mountain peaks and a sunset sun, paired with a sleek media play badge in the bottom-right corner representing video support
- Android 13+ (API 33+) Material You dynamic themed icon support (`monochrome` icon)

---

## 2. Proposed Changes

### 2.1 Files to Modify

- `android/app/src/main/res/drawable/ic_launcher_foreground.xml` — Redesign with detailed, layered vector paths (photo frame, mountains, sun, glowing play badge).
- `android/app/src/main/res/values/colors.xml` — Define rich brand palette colors for the icon elements.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — Add monochrome themed icon tag for Material You dynamic theming.
- `android/app/src/main/res/mipmap/ic_launcher.xml` — Ensure smooth fallback rendering for Android 7.0/7.1 (API 24/25).

### 2.2 Files to Create

- `android/app/src/main/res/drawable/ic_launcher_background.xml` — A gradient vector background with deep sapphire-to-cyan tones and ambient radial glow.
- `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` — Monochromatic silhouette mask for Android 13+ Material You themed icons.

---

## 3. Design Details

1. **Adaptive Safe Area Compliance**:
   Android adaptive icons use a 108dp x 108dp viewport where the inner 72dp circle/squircle is always visible (18dp outer margins are reserved for launcher masking and parallax motion). The artwork will be centered inside the 72dp safe boundary.

2. **Visual Components**:
   - **Background**: Deep sapphire gradient (`#0B1E2E` to `#004D67`) with soft circular glow.
   - **Photo Frame**: Modern rounded card with translucent cyan border and subtle drop depth.
   - **Landscape**: Dual-layer mountain peaks with sky/cyan gradient fills and a radiant golden sunset sun.
   - **Play Emblem**: Circular badge with glowing border and play triangle anchored at the lower corner, symbolizing video media.
   - **Monochrome Version**: Clean single-tone silhouette conforming to Android's Material You dynamic theming spec.

---

## 4. Verification Plan

1. Verify static analysis:
   ```bash
   flutter analyze
   ```
2. Build the development APK to ensure Android resource compiler (AAPT2) validates all vector paths and resource IDs without errors:
   ```bash
   flutter build apk --flavor dev
   ```
3. Run test suite:
   ```bash
   flutter test
   ```
