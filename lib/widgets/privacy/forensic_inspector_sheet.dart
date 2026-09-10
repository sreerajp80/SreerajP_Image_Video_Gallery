import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/forensic_metadata.dart';
import 'package:in_sreerajp_imgvidgal/providers/privacy_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// Modal sheet displaying comprehensive optical, hardware, and sensor forensic metadata.
class ForensicInspectorSheet extends ConsumerWidget {
  final MediaItem item;

  const ForensicInspectorSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MediaItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ForensicInspectorSheet(
          item: item,
        )._buildSheet(context, scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildSheet(context, null);
  }

  Widget _buildSheet(BuildContext context, ScrollController? scrollController) {
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final forensicAsync = ref.watch(mediaForensicProvider(item));

        return ListView(
          controller: scrollController,
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
                    Icons.biotech_outlined,
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
                        l10n.forensicInspectorTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.forensicInspectorSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            forensicAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.forensicNoData,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (data) => _ForensicContent(data: data),
            ),
          ],
        );
      },
    );
  }
}

class _ForensicContent extends StatelessWidget {
  final ForensicMetadata data;

  const _ForensicContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sensor & Optical Section
        _SectionCard(
          title: l10n.forensicSectionSensorOptics,
          icon: Icons.camera_outlined,
          children: [
            if (data.sensorFormat != null)
              _ForensicRow(
                label: l10n.forensicSensorFormat,
                value: data.sensorFormat!,
                badge: true,
              ),
            if (data.cropFactor != null)
              _ForensicRow(
                label: l10n.forensicCropFactor,
                value: '${data.cropFactor!.toStringAsFixed(2)}x',
              ),
            if (data.focalLength35mm != null)
              _ForensicRow(
                label: l10n.forensicFocal35mm,
                value: '${data.focalLength35mm!.toStringAsFixed(0)} mm',
              ),
            if (data.physicalFocalLength != null)
              _ForensicRow(
                label: l10n.forensicPhysicalFocalLength,
                value: '${data.physicalFocalLength!.toStringAsFixed(1)} mm',
              ),
            if (data.hyperfocalDistanceMeters != null)
              _ForensicRow(
                label: l10n.forensicHyperfocalDistance,
                value: '${data.hyperfocalDistanceMeters!.toStringAsFixed(1)} m',
              ),
            if (data.exposureBiasString != null)
              _ForensicRow(
                label: l10n.forensicExposureBias,
                value: data.exposureBiasString!,
                highlight: true,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Shutter & Color Profile Section
        _SectionCard(
          title: l10n.forensicSectionMechanicsColor,
          icon: Icons.shutter_speed_outlined,
          children: [
            _ForensicRow(
              label: l10n.forensicShutterActuations,
              value: data.shutterActuations != null
                  ? '${data.shutterActuations!} releases'
                  : l10n.forensicShutterNotReported,
            ),
            if (data.colorProfile != null)
              _ForensicRow(
                label: l10n.forensicColorProfile,
                value: data.colorProfile!,
              ),
            if (data.exposureProgram != null)
              _ForensicRow(
                label: l10n.forensicExposureProgram,
                value: data.exposureProgram!,
              ),
            if (data.meteringMode != null)
              _ForensicRow(
                label: l10n.forensicMeteringMode,
                value: data.meteringMode!,
              ),
            if (data.sensingMethod != null)
              _ForensicRow(
                label: l10n.forensicSensingMethod,
                value: data.sensingMethod!,
              ),
            if (data.sceneCaptureType != null)
              _ForensicRow(
                label: l10n.forensicSceneCaptureType,
                value: data.sceneCaptureType!,
              ),
            if (data.flashDetails != null)
              _ForensicRow(
                label: l10n.forensicFlashStatus,
                value: data.flashDetails!,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Hardware & Serial Identity Section
        _SectionCard(
          title: l10n.forensicSectionHardwareIdentity,
          icon: Icons.fingerprint_outlined,
          children: [
            _ForensicRow(
              label: l10n.forensicCameraSerial,
              value: data.bodySerialNumber ?? l10n.forensicSerialNotEmbedded,
            ),
            if (data.lensModel != null)
              _ForensicRow(
                label: l10n.forensicLensModel,
                value: data.lensModel!,
              ),
            if (data.lensSpecification != null)
              _ForensicRow(
                label: l10n.forensicLensSpecification,
                value: data.lensSpecification!,
              ),
            _ForensicRow(
              label: l10n.forensicLensSerial,
              value: data.lensSerialNumber ?? l10n.forensicSerialNotEmbedded,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ForensicRow extends StatelessWidget {
  final String label;
  final String value;
  final bool badge;
  final bool highlight;

  const _ForensicRow({
    required this.label,
    required this.value,
    this.badge = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: badge
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )
                : AdaptiveDirectionality(
                    text: value,
                    child: Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: highlight
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: highlight
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
