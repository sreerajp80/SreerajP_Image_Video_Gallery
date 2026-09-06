import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/pairing_codec.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the pairing code, as a QR image and as text to read aloud.
///
/// Both, because the QR code is the fast path and the typed code is the one
/// that still works on a phone with no camera, a broken camera, or a refused
/// camera permission. Neither is a fallback for a bug; they are two ways of
/// moving the same secret across the gap between two screens.
///
/// The QR code is drawn on a fixed white background rather than the theme's,
/// because a scanner needs the contrast and a dark-theme QR code on a dark
/// surface is one no camera will read.
class PairingQrCard extends StatelessWidget {
  final PairingPayload pairing;

  /// The typed fallback, already grouped for reading.
  final String? manualCode;

  const PairingQrCard({
    super.key,
    required this.pairing,
    required this.manualCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          l10n.syncPairingHeading,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Fixed white, whatever the theme. A scanner needs the contrast.
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: PairingCodec.encode(pairing),
            version: QrVersions.auto,
            size: 240,
            backgroundColor: Colors.white,
            // Medium correction: enough to survive a smudged screen without
            // making the code so dense a phone camera struggles at arm's
            // length, which is the distance this is actually used at.
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),

        const SizedBox(height: 24),
        Text(
          l10n.syncManualCodeHeading,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        if (manualCode != null)
          SelectableText(
            manualCode!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),

        const SizedBox(height: 16),
        Text(
          pairing.deviceName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
