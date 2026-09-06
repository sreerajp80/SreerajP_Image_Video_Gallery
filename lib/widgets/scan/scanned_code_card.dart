import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// One scanned code, with the actions it earns.
///
/// A blocked action is shown greyed out with its reason underneath rather than
/// hidden. Someone looking at a code they can plainly read deserves to know
/// why the app will not act on it, instead of finding a button missing.
class ScannedCodeCard extends StatelessWidget {
  final ScannedCode code;

  /// The actions for this code, already worked out by the resolver.
  final List<ScanAction> actions;

  /// Called when an allowed action is tapped.
  final void Function(ScanAction action) onAction;

  const ScannedCodeCard({
    super.key,
    required this.code,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_iconFor(code.kind), color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _kindLabel(l10n, code.kind),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (code.format.isNotEmpty)
                  Text(
                    code.format,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // The readable form, and never the Wi-Fi password: a password on
            // screen is a password someone across the table can read.
            //
            // A code is untrusted text off a poster or a screenshot, so it is
            // laid out the way it actually reads rather than the app's way.
            Builder(
              builder: (context) {
                final payload = code.displayValue.isEmpty
                    ? code.rawValue
                    : code.displayValue;
                return AdaptiveDirectionality(
                  text: payload,
                  child: SelectableText(
                    payload,
                    style: theme.textTheme.bodyLarge,
                    maxLines: 6,
                  ),
                );
              },
            ),

            if (code.wifi != null) ...<Widget>[
              const SizedBox(height: 8),
              _wifiDetails(context, l10n, code.wifi!),
            ],

            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final action in actions)
                  _actionChip(context, l10n, action),
              ],
            ),

            for (final action in actions)
              if (!action.isAllowed && action.blockReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _blockReason(l10n, action.blockReason!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _wifiDetails(
    BuildContext context,
    AppLocalizations l10n,
    WifiCredentials wifi,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          wifi.security.needsPassword
              ? l10n.codeScanWifiSecurity(wifi.security.name.toUpperCase())
              : l10n.codeScanWifiOpen,
          style: theme.textTheme.bodySmall,
        ),
        if (wifi.isHidden)
          Text(l10n.codeScanWifiHidden, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _actionChip(
    BuildContext context,
    AppLocalizations l10n,
    ScanAction action,
  ) {
    return ActionChip(
      avatar: Icon(_actionIcon(action.type), size: 18),
      label: Text(_actionLabel(l10n, action.type)),
      // A blocked action stays on screen but does nothing when tapped.
      onPressed: action.isAllowed ? () => onAction(action) : null,
    );
  }

  IconData _iconFor(ScannedCodeKind kind) {
    return switch (kind) {
      ScannedCodeKind.url => Icons.link,
      ScannedCodeKind.wifi => Icons.wifi,
      ScannedCodeKind.phone => Icons.phone_outlined,
      ScannedCodeKind.email => Icons.mail_outline,
      ScannedCodeKind.sms => Icons.sms_outlined,
      ScannedCodeKind.geo => Icons.place_outlined,
      ScannedCodeKind.contact => Icons.contact_page_outlined,
      ScannedCodeKind.calendar => Icons.event_outlined,
      ScannedCodeKind.text => Icons.notes_outlined,
    };
  }

  String _kindLabel(AppLocalizations l10n, ScannedCodeKind kind) {
    return switch (kind) {
      ScannedCodeKind.url => l10n.codeScanKindUrl,
      ScannedCodeKind.wifi => l10n.codeScanKindWifi,
      ScannedCodeKind.phone => l10n.codeScanKindPhone,
      ScannedCodeKind.email => l10n.codeScanKindEmail,
      ScannedCodeKind.sms => l10n.codeScanKindSms,
      ScannedCodeKind.geo => l10n.codeScanKindGeo,
      ScannedCodeKind.contact => l10n.codeScanKindContact,
      ScannedCodeKind.calendar => l10n.codeScanKindCalendar,
      ScannedCodeKind.text => l10n.codeScanKindText,
    };
  }

  IconData _actionIcon(ScanActionType type) {
    return switch (type) {
      ScanActionType.copy => Icons.copy_outlined,
      ScanActionType.openUrl => Icons.open_in_new,
      ScanActionType.dial => Icons.call_outlined,
      ScanActionType.email => Icons.mail_outline,
      ScanActionType.sms => Icons.send_outlined,
      ScanActionType.showOnMap => Icons.map_outlined,
      ScanActionType.copyWifiPassword => Icons.key_outlined,
      ScanActionType.connectWifi => Icons.wifi_find_outlined,
      ScanActionType.saveToNotes => Icons.note_add_outlined,
    };
  }

  String _actionLabel(AppLocalizations l10n, ScanActionType type) {
    return switch (type) {
      ScanActionType.copy => l10n.codeScanActionCopy,
      ScanActionType.openUrl => l10n.codeScanActionOpen,
      ScanActionType.dial => l10n.codeScanActionDial,
      ScanActionType.email => l10n.codeScanActionEmail,
      ScanActionType.sms => l10n.codeScanActionSms,
      ScanActionType.showOnMap => l10n.codeScanActionMap,
      ScanActionType.copyWifiPassword => l10n.codeScanActionCopyWifiPassword,
      ScanActionType.connectWifi => l10n.codeScanActionConnectWifi,
      ScanActionType.saveToNotes => l10n.codeScanActionSaveToNotes,
    };
  }

  String _blockReason(AppLocalizations l10n, ScanBlockReason reason) {
    return switch (reason) {
      ScanBlockReason.unsupportedScheme => l10n.codeScanBlockedScheme,
      ScanBlockReason.malformedTarget => l10n.codeScanBlockedMalformed,
      ScanBlockReason.incompleteWifi => l10n.codeScanBlockedIncompleteWifi,
      ScanBlockReason.payloadTooLong => l10n.codeScanBlockedTooLong,
    };
  }
}
