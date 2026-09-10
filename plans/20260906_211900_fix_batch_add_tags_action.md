# Plan: Fix Batch "Add Tags" and "Add to Album" Doing Nothing on Selection

**Status:** Approved

## Overview
When selecting a photo and pressing **Add tags** in the bottom batch action bar, nothing happens. This occurs because the tag picker silently returns `null` when no tags exist in the database, without displaying any UI, sheet, or option to create a tag. Furthermore, even when tags do exist, the picker did not provide a way to create and apply a new tag. A similar issue affects **Add to album** when no albums have been created yet.

This plan resolves these issues by making the tag and album batch selection sheets interactive, supporting both existing items and on-the-fly creation, and providing clear user feedback.

---

## Root Causes

1. **Silent Abort on Empty Tags**:
   In `lib/widgets/batch/batch_action_bar.dart`, `_pickTags` checks:
   ```dart
   final tags = await ref.read(allTagsProvider.future);
   if (!context.mounted || tags.isEmpty) return null;
   ```
   If the user has not created any tags yet (`tags.isEmpty`), `_pickTags` immediately returns `null`. `_gatherOptions` receives `null`, and `_start` returns silently. No UI is shown and the user is left wondering why tapping the button had no effect.

2. **No Tag Creation within Batch Picker**:
   Even if existing tags exist, the previous bottom sheet only displayed a static checkbox list of existing tags. Unlike `MediaTagSheet` (used in the single viewer), there was no text field or button to type a new tag name, create it, and apply it to the selected photos.

3. **Silent Abort on "Remove Tags"**:
   For `BatchAction.removeTags`, if no tags exist in the app, it also returns `null` silently without letting the user know there are no tags to remove.

4. **Similar Silent Abort on "Add to Album"**:
   In `_pickAlbum`, `if (!context.mounted || albums.isEmpty) return null;` causes the same silent failure when no virtual albums have been created yet.

---

## Proposed Changes

### 1. Dedicated Batch Tag Picker Sheet (`lib/widgets/batch/batch_tag_picker_sheet.dart`)
Create a responsive, user-friendly bottom sheet:
- Handles both `BatchAction.addTags` and `BatchAction.removeTags`.
- **For `addTags`**:
  - Always opens, even if no tags exist yet.
  - Displays the list of tags (if any) with checkboxes.
  - If no tags exist yet, displays a helpful empty state note (`filterNoTags`).
  - Includes a text input field and "Add" button allowing users to type a new tag name. On submission, calls `tagEditControllerProvider.notifier.findOrCreate(name)`, adds it to the list, and automatically marks it as selected.
  - "Continue" button is enabled once at least one tag is selected.
- **For `removeTags`**:
  - If `tags.isEmpty`, shows a SnackBar message informing the user that no tags exist to remove.
  - If tags exist, lets the user check which tags to remove and confirm.

### 2. Batch Action Bar Updates (`lib/widgets/batch/batch_action_bar.dart`)
- Update `_gatherOptions` to pass the specific `BatchAction` to the tag picker.
- Use `BatchTagPickerSheet.show(context, action: action)` in `_pickTags`.
- Update `_pickAlbum` to allow creating an album directly from the picker sheet using `AlbumEditDialog` and `albumEditControllerProvider.notifier.create(name)` (matching the pattern in `AlbumPickerSheet`), so tapping "Add to album" never fails silently.

### 3. Tests (`test/widgets/batch/batch_action_bar_test.dart`)
- Verify that tapping "Add tags" opens the picker sheet even when no tags exist.
- Verify adding a new tag inline in the sheet creates and selects the tag.
- Verify selecting tags and pressing Continue invokes the batch controller.
- Verify tapping "Remove tags" when no tags exist displays feedback instead of doing nothing.

---

## Verification Plan

### Automated Tests
- Run `flutter test test/widgets/batch/batch_action_bar_test.dart`
- Run static analysis: `flutter analyze`
- Run full test suite: `flutter test`

### Manual Verification
- Select a photo in the timeline grid.
- Press "Add tags" in the batch action bar.
- Verify the sheet opens with the option to type a new tag name.
- Type a new tag name, press Add, and press Continue.
- Verify the tag is created and applied to the selected photo.
