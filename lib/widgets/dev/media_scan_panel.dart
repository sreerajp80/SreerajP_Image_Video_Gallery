import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';

/// Development-only panel that exercises the Phase 3 scanner and thumbnail
/// engine on a real device.
///
/// It is shown for the `dev` flavor only, on the settings screen. Normal media
/// scanning happens from the timeline's pull-to-refresh.
class MediaScanPanel extends ConsumerWidget {
  const MediaScanPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final permission = ref.watch(mediaPermissionStatusProvider);
    final scanState = ref.watch(mediaScanControllerProvider);
    final progress = ref.watch(scanProgressProvider);
    final indexedCount = ref.watch(indexedMediaCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.scanMedia,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            permission.when(
              data: (status) => _PermissionRow(status: status),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.scanFailed),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: scanState.isLoading
                      ? null
                      : () => ref
                            .read(mediaScanControllerProvider.notifier)
                            .scan(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.scanMedia),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: indexedCount.when(
                    data: (count) => Text(l10n.indexedItems(count)),
                    loading: () => const SizedBox.shrink(),
                    error: (error, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            if (scanState.isLoading) ...[
              const SizedBox(height: 12),
              progress.when(
                data: (value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: value.fraction),
                    const SizedBox(height: 6),
                    Text(
                      value.total > 0
                          ? l10n.scanProgress(value.scanned, value.total)
                          : l10n.scanningMedia,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(l10n.scanFailed),
              ),
            ],
            scanState.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.scanComplete(result.indexed),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.scanFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _ThumbnailStrip(),
          ],
        ),
      ),
    );
  }
}

/// Shows the current permission state and the matching action button.
class _PermissionRow extends ConsumerWidget {
  final MediaPermissionStatus status;

  const _PermissionRow({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (status == MediaPermissionStatus.granted) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.permissionRequired)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status == MediaPermissionStatus.partial
              ? l10n.permissionPartial
              : l10n.permissionRequiredBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (status == MediaPermissionStatus.permanentlyDenied)
          OutlinedButton(
            onPressed: () async {
              await ref.read(mediaPermissionServiceProvider).openSettings();
              ref.invalidate(mediaPermissionStatusProvider);
            },
            child: Text(l10n.openSettings),
          )
        else
          OutlinedButton(
            onPressed: () async {
              await ref.read(mediaPermissionServiceProvider).request();
              ref.invalidate(mediaPermissionStatusProvider);
            },
            child: Text(l10n.grantPermission),
          ),
      ],
    );
  }
}

/// Small horizontal strip proving the thumbnail engine works end to end.
class _ThumbnailStrip extends ConsumerWidget {
  const _ThumbnailStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(mediaItemsProvider(const FilterOptions()));

    return items.when(
      data: (media) {
        if (media.isEmpty) {
          return Text(
            l10n.noMediaFound,
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final preview = media.take(12).toList(growable: false);
        return SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                MediaThumbnail(item: preview[index], size: 88),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Text(l10n.scanFailed, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
