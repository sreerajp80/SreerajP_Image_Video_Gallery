import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';

/// Banner that lists what private data the photo's metadata still holds.
class PrivacyAuditCard extends StatelessWidget {
  final ExifData? exif;

  const PrivacyAuditCard({super.key, required this.exif});

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
                      ? l10n.bodyPrivacyAuditSensitiveDetected
                      : l10n.bodyPrivacyAuditClean,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasAnySensitive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  hasAnySensitive
                      ? l10n.bodyPrivacyAuditSensitiveDetails(
                          hasLocation ? l10n.labelPrivacyAuditGps : '',
                          hasCamera ? l10n.labelPrivacyAuditCamera : '',
                        )
                      : l10n.bodyPrivacyAuditCleanDetails,
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
