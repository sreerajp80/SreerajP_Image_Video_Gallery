import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/formatting_locale.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/gps_fuzz_result.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';
import 'package:in_sreerajp_imgvidgal/providers/privacy_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_export_result.dart';
import 'package:in_sreerajp_imgvidgal/widgets/privacy/forensic_inspector_sheet.dart';
import 'package:intl/intl.dart';
import 'package:in_sreerajp_imgvidgal/widgets/privacy/privacy_audit_card.dart';

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

  PrivacyScrubOptions get _scrubOptions => PrivacyScrubOptions(
    stripAllExif: _stripAll,
    stripLocation: _stripLocation,
    stripCameraAndLensSerials: _stripSerials,
    stripTimestamps: _stripTimestamps,
    stripAuthorAndSoftware: _stripAuthor,
  );

  /// Runs one export (through `privacyExportServiceProvider`) and reports
  /// the result.
  ///
  /// [doneMessage] is shown only for saves; a finished share needs no
  /// message because the share sheet itself was the feedback.
  Future<void> _export({
    required Future<PrivacyExportResult> Function() action,
    required bool isSave,
    String? doneMessage,
  }) async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final result = await action();
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final message = switch (result) {
      PrivacyExportResult.done => doneMessage,
      PrivacyExportResult.unreadable => l10n.bodyPrivacyErrorReadingFile,
      PrivacyExportResult.shareFailed => l10n.errorPrivacyShareFailed,
      PrivacyExportResult.failed =>
        isSave ? l10n.errorPrivacySaveFailed : l10n.errorPrivacyProcess,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleStripAndShare() {
    final l10n = AppLocalizations.of(context)!;
    return _export(
      isSave: false,
      action: () => ref
          .read(privacyExportServiceProvider)
          .shareScrubbed(
            widget.item,
            _scrubOptions,
            shareTitle: l10n.titlePrivacyShare,
          ),
    );
  }

  Future<void> _handleSaveSanitizedCopy() {
    final l10n = AppLocalizations.of(context)!;
    return _export(
      isSave: true,
      doneMessage: l10n.bodyPrivacySavedToGallery,
      action: () => ref
          .read(privacyExportServiceProvider)
          .saveScrubbed(widget.item, _scrubOptions),
    );
  }

  Future<void> _handleFuzzAndShare() async {
    final fuzz = _fuzzResult;
    if (fuzz == null) return;
    final l10n = AppLocalizations.of(context)!;
    return _export(
      isSave: false,
      action: () => ref
          .read(privacyExportServiceProvider)
          .shareFuzzed(widget.item, fuzz, shareTitle: l10n.titleGeofenceShare),
    );
  }

  Future<void> _handleSaveFuzzedCopy() async {
    final fuzz = _fuzzResult;
    if (fuzz == null) return;
    final l10n = AppLocalizations.of(context)!;
    return _export(
      isSave: true,
      doneMessage: l10n.bodyGeofenceSavedToGallery,
      action: () =>
          ref.read(privacyExportServiceProvider).saveFuzzed(widget.item, fuzz),
    );
  }

  /// A fixed-distance chip label, with the number in the user's locale.
  String _distanceLabel(BuildContext context, double km) {
    final locale = formattingLocale(Localizations.localeOf(context));
    final number = NumberFormat('0.0', locale).format(km);
    return AppLocalizations.of(context)!.labelDistanceKm(number);
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
                    l10n.tooltipPrivacyScrubberTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.descPrivacyScrubberSubtitle,
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
          error: (_, _) => const SizedBox.shrink(),
          data: (exif) => PrivacyAuditCard(exif: exif),
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
              text: l10n.labelPrivacyTabStripper,
            ),
            Tab(
              icon: const Icon(Icons.share_location_outlined),
              text: l10n.labelPrivacyTabGeofence,
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
                error: (_, _) =>
                    Center(child: Text(l10n.bodyPrivacyNoLocation)),
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
            l10n.titleForensicInspector,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(l10n.helpForensicInspectorQuickHint),
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
          label: Text(l10n.actionPrivacyStripAndShare),
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
          label: Text(l10n.actionPrivacySaveSanitized),
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
                      l10n.titlePrivacyGranular,
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
                        _stripAll
                            ? l10n.labelPrivacyCustom
                            : l10n.labelPrivacyStripAll,
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.titlePrivacyOptionGps),
                  value: _stripLocation,
                  onChanged: (val) => setState(() {
                    _stripLocation = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.titlePrivacyOptionSerials),
                  value: _stripSerials,
                  onChanged: (val) => setState(() {
                    _stripSerials = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.titlePrivacyOptionTimestamps),
                  value: _stripTimestamps,
                  onChanged: (val) => setState(() {
                    _stripTimestamps = val ?? true;
                    _stripAll = false;
                  }),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.titlePrivacyOptionAuthor),
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
                l10n.labelGeofenceNoCoordinates,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.bodyGeofenceNoCoordinates,
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
              l10n.bodyGeofenceOffsetDistance,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: l10n.tooltipGeofenceReroll,
              icon: const Icon(Icons.refresh),
              onPressed: () => _generateFuzz(exif!),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.labelGeofenceRandomPreset),
              selected: _isRandomDistance,
              onSelected: (val) {
                if (val) {
                  setState(() => _isRandomDistance = true);
                  _generateFuzz(exif!);
                }
              },
            ),
            ChoiceChip(
              label: Text(_distanceLabel(context, 2.0)),
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
              label: Text(_distanceLabel(context, 3.5)),
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
              label: Text(_distanceLabel(context, 5.0)),
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
                        l10n.bodyGeofenceShiftSummary(_fuzzResult!.summary),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.bodyGeofenceFuzzedCoordinates(
                      _fuzzResult!.fuzzedLatitude.toStringAsFixed(4),
                      _fuzzResult!.fuzzedLongitude.toStringAsFixed(4),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.descGeofenceExplanation,
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
          label: Text(l10n.actionGeofenceShare),
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
          label: Text(l10n.actionGeofenceSave),
        ),
      ],
    );
  }
}
