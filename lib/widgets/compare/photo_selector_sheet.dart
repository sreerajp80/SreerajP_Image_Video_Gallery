import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

/// Modal bottom sheet allowing the user to select an alternate photo from
/// the gallery to compare against.
class PhotoSelectorSheet extends ConsumerWidget {
  /// Optional media ID to exclude from selection (e.g. the photo already in the other slot).
  final String? excludeMediaId;

  const PhotoSelectorSheet({super.key, this.excludeMediaId});

  /// Displays the sheet and returns the picked [MediaItem], or null if dismissed.
  static Future<MediaItem?> show(
    BuildContext context, {
    String? excludeMediaId,
  }) {
    return showModalBottomSheet<MediaItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PhotoSelectorSheet(excludeMediaId: excludeMediaId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const filter = FilterOptions(
      mediaTypes: {MediaType.image, MediaType.rawImage},
      sortDirection: SortDirection.descending,
    );
    final mediaAsync = ref.watch(mediaItemsProvider(filter));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.compareSelectSecondPhoto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: mediaAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.mediaUnavailable,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = excludeMediaId == null
                      ? items
                      : items.where((i) => i.id != excludeMediaId).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMediaFound,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _PhotoGridTile(
                        item: item,
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoGridTile extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const _PhotoGridTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbAsync = ref.watch(thumbnailProvider(item));
    final bytes = thumbAsync.valueOrNull;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: bytes != null && bytes.isNotEmpty
              ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
              : (thumbAsync.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.broken_image_outlined, size: 28),
                      )),
        ),
      ),
    );
  }
}
