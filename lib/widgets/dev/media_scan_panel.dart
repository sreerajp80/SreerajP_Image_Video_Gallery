import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
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
              l10n.labelScanMedia,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            permission.when(
              data: (status) => _PermissionRow(status: status),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(l10n.errorScanFailed),
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
                  label: Text(l10n.labelScanMedia),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: indexedCount.when(
                    data: (count) => Text(l10n.bodyIndexedItems(count)),
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
                          ? l10n.bodyScanProgress(value.scanned, value.total)
                          : l10n.bodyScanningMedia,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(l10n.errorScanFailed),
              ),
            ],
            scanState.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.bodyScanComplete(result.indexed),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.errorScanFailed,
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
          Expanded(child: Text(l10n.labelPermissionRequired)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status == MediaPermissionStatus.partial
              ? l10n.bodyPermissionPartial
              : l10n.bodyPermissionRequired,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (status == MediaPermissionStatus.permanentlyDenied)
          OutlinedButton(
            onPressed: () async {
              await ref.read(mediaPermissionServiceProvider).openSettings();
              ref.invalidate(mediaPermissionStatusProvider);
            },
            child: Text(l10n.labelOpenSettings),
          )
        else
          OutlinedButton(
            onPressed: () async {
              await ref.read(mediaPermissionServiceProvider).request();
              ref.invalidate(mediaPermissionStatusProvider);
            },
            child: Text(l10n.labelGrantPermission),
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
            l10n.bodyNoMediaFound,
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
      error: (error, _) => Text(
        l10n.errorScanFailed,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
