import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_card.dart';

/// The Folders tab, showing every device folder that holds indexed media.
///
/// Tapping a folder navigates to the folder-media grid at
/// `/albums/folder/:path`. The list refreshes after a scan.
class FoldersTab extends ConsumerWidget {
  const FoldersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final folders = ref.watch(deviceFolderAlbumsProvider);
    final scanState = ref.watch(mediaScanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foldersTitle),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(kRouteSearch),
            icon: const Icon(Icons.search),
            tooltip: l10n.searchOpen,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (scanState.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: folders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.albumsLoadFailed,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(mediaScanControllerProvider.notifier)
                          .scan(incremental: true),
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_off_outlined,
                                          size: 56,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l10n.foldersEmpty,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          l10n.foldersEmptyBody,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(mediaScanControllerProvider.notifier)
                        .scan(incremental: true),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            // Card aspect ratio: square cover + two lines of text.
                            childAspectRatio: 0.78,
                          ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final folder = list[index];
                        return AlbumCard(
                          summary: folder,
                          size: null,
                          onTap: () => context.push(folderAlbumPath(folder.id)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
