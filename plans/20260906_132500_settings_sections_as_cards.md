# Display Settings Sections as Cards

**Status:** completed

**Date:** 2026-09-06  
**Reference:** SreerajPContactSphere settings section card layout  

---

## 1. Goal & Context

In `lib/screens/settings/settings_screen.dart`, settings options are currently laid out as loose rows separated by full-width divider lines on the page background.

The requirement is to display each settings section inside its own dedicated `Card` container, following the design system seen in `SreerajPContactSphere`:
- Appearance Section: Card enclosing Theme selector, Grid density slider, and Memories toggle.
- Language Section: Card enclosing System Default, English, and Malayalam choices with explanation.
- Safety Section: Card enclosing destructive action confirmation toggle.
- Storage and Privacy Section: Card enclosing offline guarantee note, vault settings link, and backup link.
- Developer Section (dev flavor only): Card enclosing the media scan panel.
- Help & Guides Section: Card enclosing help guide topics with clear leading icons and chevrons.
- About Section: Card enclosing About app link and Reset settings action.

---

## 2. Proposed Changes

### `lib/screens/settings/settings_screen.dart`
- Change outer `ListView` padding to `EdgeInsets.fromLTRB(16, 8, 16, 32)` to give consistent page margins for cards.
- Update `_SectionHeader` padding to `EdgeInsets.fromLTRB(4, 16, 4, 8)` so titles align with the card bounds with a clean hierarchy.
- Remove loose full-width dividers between sections.
- Wrap each section's contents in a Material 3 `Card` with:
  - `margin: EdgeInsets.zero`
  - `clipBehavior: Clip.antiAlias`
- Inside multi-item cards, separate items using subtle inner dividers (`Divider(height: 1, indent: 16, endIndent: 16)`).
- Provide clean internal padding for custom controls (`_ThemeRow`, `_GridDensityRow`, `_LanguageRow`).
- Style `ListTile` items in the Storage/Privacy and About sections with clear typography, primary-tinted icons, and chevron indicators.
- For the Help section, present help topics neatly within the card layout with themed icon containers and chevrons.

### `test/widgets/settings/settings_screen_test.dart`
- Verify that every settings section renders inside a `Card` widget.
- Verify that existing settings interactions (theme changes, language changes, toggle changes, reset dialog) continue to work as expected.

---

## 3. Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure zero analysis warnings.
- Run `flutter test test/widgets/settings/settings_screen_test.dart` to verify settings screen tests.
- Run `flutter test` across the full test suite to guarantee no regressions.

### Manual Verification
- Review the settings screen in light, dark, and AMOLED modes to verify card surfaces, rounded borders, and internal spacing.
