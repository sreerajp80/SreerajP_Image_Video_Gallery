# Plan — Stop the vault reloading on every touch (fixes long-press selection)

**Status:** completed

## The issue

On the test phone (2026-11-25), long-press on a vault tile never selected anything, so items
could not be restored or deleted. The vault also felt slower than it should.

**Cause.** `VaultAutoLockScope` calls `VaultLockController.noteActivity()` on every pointer
down and every pointer move. That writes a new `lastActivityAt` into the lock state. Three
providers watch the **whole** lock state, so they all run again on every touch:

| Provider (`lib/providers/vault_providers.dart`) | What it redoes on each touch |
|---|---|
| `vaultItemsProvider` | Reads every vault row from the database again |
| `vaultItemProvider(id)` | Reads that row again |
| `vaultThumbnailProvider(id)` | Reads the row and **decrypts the preview again**, for every tile on screen |

While `vaultItemsProvider` reloads, `VaultScreen` (`items.when(loading: …)`) shows a spinner
in place of the grid. The tile under the finger is removed mid-press, so the long-press
gesture is cancelled. Scrolling sends many move events, so the list is reloaded and every
visible preview decrypted again, over and over.

These providers only need to know whether the vault is **open**. The idle time is for the
auto-lock timer alone.

## The fix

- In all three providers, watch only the open flag:
  `ref.watch(vaultLockControllerProvider.select((lock) => lock.isUnlocked))`.
  This is the same pattern already used in the viewer and the settings screen. A touch then
  changes nothing they depend on, and locking or unlocking still refreshes them at once, so a
  shut vault still has nothing in memory.
- `VaultScreen`: while a reload is running after the first load (for example after a batch
  bumps the revision), keep showing the current grid instead of the spinner
  (`skipLoadingOnReload: true`). A refresh should never take the grid away mid-gesture.

The gate screen also watches the whole lock state, but it needs to: it shows the PIN lockout
countdown. It is not touched.

## Files to change

| File | Change |
|------|--------|
| `lib/providers/vault_providers.dart` | The three providers watch `select((lock) => lock.isUnlocked)` |
| `lib/screens/vault/vault_screen.dart` | `items.when(skipLoadingOnReload: true, …)` |
| `test/providers/vault_providers_test.dart` | New tests: `noteActivity()` does not re-run `vaultItemsProvider`, `vaultItemProvider` or `vaultThumbnailProvider` (call counters on the fake repository); locking still empties them |

No new string, package, permission or database change.

## Security impact

None. Locking still clears every list and every decrypted preview on the same frame, because
the open flag changes then. Only the per-touch reloads go away.

## Checks after the change

- `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- On the test phone (dev build):
  - long-press a vault tile → it is selected;
  - select two → Restore to a folder → the files come back out;
  - scroll the grid and check it no longer flickers.
- Stop the Gradle daemons afterwards.
