import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/folder_path_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/smart_album_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_media_grid.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/smart_filter_sheet.dart';

/// One smart album at `/albums/auto/:type`.
///
/// Read only apart from the filter sheet: a smart album's membership comes
/// from its rule, so there is nothing here to add or remove by hand.
class SmartAlbumScreen extends ConsumerWidget {
  /// The route key naming which smart album to show.
  final String albumKey;

  const SmartAlbumScreen({super.key, required this.albumKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final album = SmartAlbumService.fromKey(albumKey);
    final media = ref.watch(smartAlbumMediaProvider(albumKey));
    final filter = ref.watch(albumFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          album == null
              ? l10n.albumsTitle
              : smartAlbumLabel(l10n, album.albumType),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => SmartFilterSheet.show(
              context,
              filterProvider: albumFilterProvider,
              showTags: false,
            ),
            icon: Icon(
              filter.hasActiveFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            tooltip: l10n.filterTitle,
          ),
        ],
      ),
      body: SafeArea(
        child: media.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AlbumErrorState(),
          data: (items) {
            if (items == null) {
              return AlbumErrorState(message: l10n.smartAlbumUnknown);
            }
            return AlbumMediaGrid(
              items: items,
              emptyTitle: l10n.smartAlbumEmptyTitle,
            );
          },
        ),
      ),
    );
  }
}

/// One device folder at `/albums/folder/:path`.
class FolderAlbumScreen extends ConsumerWidget {
  /// The directory this screen lists.
  final String directory;

  const FolderAlbumScreen({super.key, required this.directory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final media = ref.watch(folderMediaProvider(directory));
    final filter = ref.watch(albumFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(FolderPathRules.displayName(directory)),
        actions: <Widget>[
          IconButton(
            onPressed: () => SmartFilterSheet.show(
              context,
              filterProvider: albumFilterProvider,
              showTags: false,
            ),
            icon: Icon(
              filter.hasActiveFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            tooltip: l10n.filterTitle,
          ),
        ],
      ),
      body: SafeArea(
        child: media.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AlbumErrorState(),
          data: (items) =>
              AlbumMediaGrid(items: items, emptyTitle: l10n.folderEmptyTitle),
        ),
      ),
    );
  }
}
