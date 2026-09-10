import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/gps_fuzz_result.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/privacy_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/privacy/forensic_inspector_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Modal sheet for EXIF metadata stripping, GPS geofence shifting, and privacy controls.
class MediaPrivacySheet extends ConsumerStatefulWidget {
  final MediaItem item;

  const MediaPrivacySheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MediaItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => MediaPrivacySheet(
          item: item,
        )._buildWrapper(context, scrollController),
      ),
    );
  }

  Widget _buildWrapper(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return _MediaPrivacyBody(item: item, scrollController: scrollController);
  }

  @override
  ConsumerState<MediaPrivacySheet> createState() => _MediaPrivacySheetState();
}

class _MediaPrivacySheetState extends ConsumerState<MediaPrivacySheet> {
  @override
  Widget build(BuildContext context) {
    return _MediaPrivacyBody(item: widget.item, scrollController: null);
  }
}

class _MediaPrivacyBody extends ConsumerStatefulWidget {
  final MediaItem item;
  final ScrollController? scrollController;

  const _MediaPrivacyBody({required this.item, required this.scrollController});

  @override
  ConsumerState<_MediaPrivacyBody> createState() => _MediaPrivacyBodyState();
}

class _MediaPrivacyBodyState extends ConsumerState<_MediaPrivacyBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stripper options
  bool _stripAll = true;
  bool _stripLocation = true;
  bool _stripSerials = true;
  bool _stripTimestamps = true;
  bool _stripAuthor = true;
  bool _isProcessing = false;

  // Geofence fuzzer state
  GpsFuzzResult? _fuzzResult;
  double _fuzzDistanceKm = 3.5;
  bool _isRandomDistance = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateFuzz(ExifData exif) {
    final lat = exif.latitude;
    final lon = exif.longitude;
    if (lat == null || lon == null) return;

    final geofenceService = ref.read(gpsGeofenceServiceProvider);
    setState(() {
      _fuzzResult = geofenceService.calculateFuzz(
        latitude: lat,
        longitude: lon,
        fixedDistanceKm: _isRandomDistance ? null : _fuzzDistanceKm,
      );
    });
  }

  Future<void> _handleStripAndShare() async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final rawBytes = await repository.readOriginalBytes(widget.item);
      if (rawBytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyErrorReadingFile)),
        );
        return;
      }

      final options = PrivacyScrubOptions(
        stripAllExif: _stripAll,
        stripLocation: _stripLocation,
        stripCameraAndLensSerials: _stripSerials,
        stripTimestamps: _stripTimestamps,
        stripAuthorAndSoftware: _stripAuthor,
      );

      final scrubber = ref.read(exifScrubberServiceProvider);
      final sanitizedBytes = await scrubber.scrubBytes(
        rawBytes,
        options: options,
      );

      final shareService = ref.read(shareServiceProvider);
      final filename = 'scrubbed_${widget.item.displayName}';
      final ok = await shareService.shareBytes(
        bytes: sanitizedBytes,
        filename: filename,
        mimeType: widget.item.mimeType,
        title: l10n.privacyShareTitle,
      );

      if (!ok && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyShareFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyProcessError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSaveSanitizedCopy() async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final rawBytes = await repository.readOriginalBytes(widget.item);
      if (rawBytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyErrorReadingFile)),
        );
        return;
      }

      final options = PrivacyScrubOptions(
        stripAllExif: _stripAll,
        stripLocation: _stripLocation,
        stripCameraAndLensSerials: _stripSerials,
        stripTimestamps: _stripTimestamps,
        stripAuthorAndSoftware: _stripAuthor,
      );

      final scrubber = ref.read(exifScrubberServiceProvider);
      final sanitizedBytes = await scrubber.scrubBytes(
        rawBytes,
        options: options,
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedFilename =
          'clean_${DateTime.now().millisecondsSinceEpoch}_${widget.item.displayName}';
      final tempFile = File(p.join(tempDir.path, sanitizedFilename));
      await tempFile.writeAsBytes(sanitizedBytes, flush: true);

      final channel = ref.read(mediaStoreChannelProvider);
      await channel.publishFile(
        sourcePath: tempFile.path,
        displayName: sanitizedFilename,
        mimeType: widget.item.mimeType,
        isVideo: false,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacySavedToGallery)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.privacySaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleFuzzAndShare() async {
    if (_fuzzResult == null) return;
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final rawBytes = await repository.readOriginalBytes(widget.item);
      if (rawBytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyErrorReadingFile)),
        );
        return;
      }

      final geofenceService = ref.read(gpsGeofenceServiceProvider);
      final fuzzedBytes = geofenceService.applyFuzzToImageBytes(
        bytes: rawBytes,
        fuzzResult: _fuzzResult!,
      );

      final shareService = ref.read(shareServiceProvider);
      final filename = 'geofuzzed_${widget.item.displayName}';
      final ok = await shareService.shareBytes(
        bytes: fuzzedBytes,
        filename: filename,
        mimeType: widget.item.mimeType,
        title: l10n.geofenceShareTitle,
      );

      if (!ok && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyShareFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyProcessError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSaveFuzzedCopy() async {
    if (_fuzzResult == null) return;
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final rawBytes = await repository.readOriginalBytes(widget.item);
      if (rawBytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyErrorReadingFile)),
        );
        return;
      }

      final geofenceService = ref.read(gpsGeofenceServiceProvider);
      final fuzzedBytes = geofenceService.applyFuzzToImageBytes(
        bytes: rawBytes,
        fuzzResult: _fuzzResult!,
      );

      final tempDir = await getTemporaryDirectory();
      final fuzzedFilename =
          'fuzzed_${DateTime.now().millisecondsSinceEpoch}_${widget.item.displayName}';
      final tempFile = File(p.join(tempDir.path, fuzzedFilename));
      await tempFile.writeAsBytes(fuzzedBytes, flush: true);

      final channel = ref.read(mediaStoreChannelProvider);
      await channel.publishFile(
        sourcePath: tempFile.path,
        displayName: fuzzedFilename,
        mimeType: widget.item.mimeType,
        isVideo: false,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.geofenceSavedToGallery)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.privacySaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exifAsync = ref.watch(mediaExifProvider(widget.item));

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.privacyScrubberTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.privacyScrubberSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Privacy Audit Banner
        exifAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (exif) => _PrivacyAuditCard(exif: exif),
        ),
        const SizedBox(height: 16),

        // Tabs: Stripper vs Geofence
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(
              icon: const Icon(Icons.cleaning_services_outlined),
              text: l10n.privacyTabStripper,
            ),
            Tab(
              icon: const Icon(Icons.share_location_outlined),
              text: l10n.privacyTabGeofence,
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: One-Tap EXIF Stripper
              _buildStripperTab(context),

              // Tab 2: GPS Geofence Shifter
              exifAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.privacyNoLocation)),
                data: (exif) => _buildGeofenceTab(context, exif),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),

        // Link to Forensic Inspector
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.biotech_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            l10n.forensicInspectorTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(l10n.forensicInspectorQuickHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            ForensicInspectorSheet.show(context, widget.item);
          },
        ),
      ],
    );
  }

  Widget _buildStripperTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      children: [
        // Primary Action: Strip & Share
        FilledButton.icon(
          onPressed: _isProcessing ? null : _handleStripAndShare,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(l10n.privacyStripAndShareAction),
        ),
        const SizedBox(height: 10),

        // Secondary Action: Save to Gallery
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _handleSaveSanitizedCopy,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save_alt_outlined),
          label: Text(l10n.privacySaveSanitizedAction),
        ),
        const SizedBox(height: 16),

        // Granular Scrubbing Options
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.privacyGranularTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _stripAll = !_stripAll;
                          if (_stripAll) {
                            _stripLocation = true;
                            _stripSerials = true;
                            _stripTimestamps = true;
                            _stripAuthor = true;
                          }
                        });
                      },
                      child: Text(
                        _stripAll ? l10n.privacyCustom : l10n.privacyStripAll,
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyOptionGps),
                  value: _stripLocation,
                  onChanged: (val) => setState(() {
                    _stripLocation = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyOptionSerials),
                  value: _stripSerials,
                  onChanged: (val) => setState(() {
                    _stripSerials = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyOptionTimestamps),
                  value: _stripTimestamps,
                  onChanged: (val) => setState(() {
                    _stripTimestamps = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyOptionAuthor),
                  value: _stripAuthor,
                  onChanged: (val) => setState(() {
                    _stripAuthor = val ?? true;
                    _stripAll = false;
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeofenceTab(BuildContext context, ExifData? exif) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (exif?.latitude == null || exif?.longitude == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.geofenceNoCoordinates,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.geofenceNoCoordinatesBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_fuzzResult == null) {
      _generateFuzz(exif!);
    }

    return ListView(
      children: [
        // Displacement distance chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.geofenceOffsetDistance,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: l10n.geofenceReroll,
              icon: const Icon(Icons.refresh),
              onPressed: () => _generateFuzz(exif!),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.geofenceRandomPreset),
              selected: _isRandomDistance,
              onSelected: (val) {
                if (val) {
                  setState(() => _isRandomDistance = true);
                  _generateFuzz(exif!);
                }
              },
            ),
            ChoiceChip(
              label: const Text('2.0 km'),
              selected: !_isRandomDistance && _fuzzDistanceKm == 2.0,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _isRandomDistance = false;
                    _fuzzDistanceKm = 2.0;
                  });
                  _generateFuzz(exif!);
                }
              },
            ),
            ChoiceChip(
              label: const Text('3.5 km'),
              selected: !_isRandomDistance && _fuzzDistanceKm == 3.5,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _isRandomDistance = false;
                    _fuzzDistanceKm = 3.5;
                  });
                  _generateFuzz(exif!);
                }
              },
            ),
            ChoiceChip(
              label: const Text('5.0 km'),
              selected: !_isRandomDistance && _fuzzDistanceKm == 5.0,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _isRandomDistance = false;
                    _fuzzDistanceKm = 5.0;
                  });
                  _generateFuzz(exif!);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live Fuzz Preview Card
        if (_fuzzResult != null)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.near_me_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.geofenceShiftSummary(_fuzzResult!.summary),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.geofenceFuzzedCoordinates(
                      _fuzzResult!.fuzzedLatitude.toStringAsFixed(4),
                      _fuzzResult!.fuzzedLongitude.toStringAsFixed(4),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.geofenceExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Actions
        FilledButton.icon(
          onPressed: _isProcessing ? null : _handleFuzzAndShare,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.geofenceShareAction),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _handleSaveFuzzedCopy,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save_alt_outlined),
          label: Text(l10n.geofenceSaveAction),
        ),
      ],
    );
  }
}

class _PrivacyAuditCard extends StatelessWidget {
  final ExifData? exif;

  const _PrivacyAuditCard({required this.exif});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasLocation = exif?.latitude != null && exif?.longitude != null;
    final hasCamera = exif?.make != null || exif?.model != null;
    final hasDate = exif?.dateTimeOriginal != null;

    final hasAnySensitive = hasLocation || hasCamera || hasDate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasAnySensitive
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAnySensitive
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasAnySensitive
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: hasAnySensitive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAnySensitive
                      ? l10n.privacyAuditSensitiveDetected
                      : l10n.privacyAuditClean,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasAnySensitive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  hasAnySensitive
                      ? l10n.privacyAuditSensitiveDetails(
                          hasLocation ? l10n.privacyAuditGps : '',
                          hasCamera ? l10n.privacyAuditCamera : '',
                        )
                      : l10n.privacyAuditCleanDetails,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
