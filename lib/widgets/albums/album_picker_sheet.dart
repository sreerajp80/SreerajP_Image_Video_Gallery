import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_edit_dialog.dart';

/// The "add to album" sheet, opened from the viewer.
///
/// The ticks are held here and written once, on close, as a difference against
/// what the item was already in. Writing on every tap would mean a user who
/// changes their mind leaves rows behind for albums they never wanted.
class AlbumPickerSheet extends ConsumerStatefulWidget {
  final String mediaId;

  const AlbumPickerSheet({super.key, required this.mediaId});

  /// Opens the sheet for one media item.
  static Future<void> show(BuildContext context, String mediaId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AlbumPickerSheet(mediaId: mediaId),
    );
  }

  @override
  ConsumerState<AlbumPickerSheet> createState() => _AlbumPickerSheetState();
}

class _AlbumPickerSheetState extends ConsumerState<AlbumPickerSheet> {
  /// The ticked albums, or null until the stored set has been read.
  Set<String>? _selected;

  Future<void> _createAlbum() async {
    final existing =
        ref.read(virtualAlbumsProvider).valueOrNull ?? const <AlbumSummary>[];
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          AlbumEditDialog(existingNames: existing.map((a) => a.name).toList()),
    );
    if (name == null) return;

    final album = await ref
        .read(albumEditControllerProvider.notifier)
        .create(name);
    if (album == null) {
      if (mounted) _reportFailure();
      return;
    }
    // A newly made album is ticked straight away: making one from inside this
    // sheet only makes sense as a way of putting this item into it.
    setState(() => _selected = <String>{...?_selected, album.id});
  }

  Future<void> _save() async {
    final selected = _selected;
    final navigator = Navigator.of(context);
    if (selected != null) {
      await ref
          .read(albumEditControllerProvider.notifier)
          .setAlbumsForMedia(widget.mediaId, selected);
    }
    if (!mounted) return;

    final failed = ref.read(albumEditControllerProvider).hasError;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed ? l10n.albumErrorFailed : l10n.albumPickerSaved),
      ),
    );
  }

  void _reportFailure() {
    if (!ref.read(albumEditControllerProvider).hasError) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.albumErrorFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final albums = ref.watch(virtualAlbumsProvider);
    final current = ref.watch(albumsForMediaProvider(widget.mediaId));

    // The stored membership seeds the ticks once, then the user's own choices
    // take over; re-seeding on every rebuild would undo every tap.
    _selected ??= current.valueOrNull?.toSet();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.albumPickerTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _createAlbum,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.albumPickerCreate),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: albums.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(l10n.albumsLoadFailed),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(l10n.albumPickerEmpty),
                    );
                  }
                  final selected = _selected ?? const <String>{};
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final album = list[index];
                      return CheckboxListTile(
                        value: selected.contains(album.id),
                        title: Text(album.name),
                        subtitle: Text(l10n.albumItemCount(album.itemCount)),
                        onChanged: (_) => setState(() {
                          final next = <String>{...selected};
                          if (!next.remove(album.id)) next.add(album.id);
                          _selected = next;
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.albumPickerDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
