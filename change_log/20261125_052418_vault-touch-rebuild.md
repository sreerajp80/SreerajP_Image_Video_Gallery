# Change log — Stop the vault reloading on every touch (fixes long-press selection)

Implements: [plans/20261125_051858_vault-touch-rebuild.md](../plans/20261125_051858_vault-touch-rebuild.md)

## What changed

- `lib/providers/vault_providers.dart`:
  - New private `_vaultOpenProvider` (`Provider<bool>`). It watches only
    `vaultLockControllerProvider.select((lock) => lock.isUnlocked)`.
  - `vaultItemsProvider`, `vaultItemProvider` and `vaultThumbnailProvider` watch it instead of
    the whole lock state. A touch, which only changes `lastActivityAt`, no longer makes them
    read the rows and decrypt the previews again. Locking still flips the flag, so a shut vault
    still holds nothing.
- `lib/screens/vault/vault_screen.dart`: `items.when(skipLoadingOnReload: true, …)`. A refresh
  (after a batch or a format upgrade) keeps the grid on screen instead of swapping in a
  spinner mid-gesture.

## Tests

`test/providers/vault_providers_test.dart`, new group "a touch reloads nothing":
- five `noteActivity()` calls do not re-run `vaultItemsProvider`, `vaultItemProvider` or
  `vaultThumbnailProvider` (call counters on the fake repository);
- locking still empties the list and drops the previews.

**Checked that the test catches the bug.** With the old pattern put back for a moment
(`vaultItemsProvider` watching the whole lock state), "the item list is not read again"
failed. The fix was then restored.

A first attempt at that check, which changed only the new helper, still passed. A
`Provider<bool>` does not notify its watchers when the value stays the same, so the helper is
safe whichever way it is written. What mattered was what the content providers watch.

## Checks

- `dart format`: no changes.
- `flutter analyze`: no issues.
- `flutter test`: all 2580 passed.

### Phone test (2026-11-25)

Dev build on the test phone (Android 10).

- **Long-press now selects:** "1 selected" with Restore and Delete actions; a tap adds a second
  item ("2 selected").
- **Restore failed, for a reason this change did not cause.** Restoring the two items wrote
  nothing, and both stayed in the vault. The message shown was "Nothing could be moved to the
  vault", which is the import message, not a restore one. Restore writes the file back with
  plain file I/O (`saveBytes` to `/sdcard/Pictures/...`). The app runs under scoped storage on
  Android 10 (`appops`: `LEGACY_STORAGE: ignore`), which most likely blocks that write. Not
  yet confirmed in code. **This needs its own plan**, and it matters: Restore is how the owner
  would keep a second copy of the real vault before updating.
- The scrolling flicker was not checked by eye. The unit tests cover the reloads that caused
  it.
- Test folder removed from the phone, Gradle daemons stopped.

## Security impact

None. Locking still clears every list and every decrypted preview at once.
