import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';

/// Decides what may be done with a scanned code.
///
/// Pure, and the single place that answers the question. This is the
/// security-shaped part of the scanner: a code is untrusted text, and the one
/// dangerous thing an app can do with untrusted text is hand it to another app
/// as an intent. So the rule is a list of permitted schemes rather than a list
/// of forbidden ones, and anything not on the list is shown as plain text.
///
/// `javascript:`, `file:`, `content:`, `intent:` and every other scheme are
/// refused here, before the channel is ever reached. The Kotlin side checks
/// again, because one gate is never quite enough.
class ScanActionResolver {
  const ScanActionResolver();

  /// The actions offered for [code], in the order they should be shown.
  ///
  /// A blocked action is included rather than dropped, so the sheet can grey
  /// it out and say why.
  List<ScanAction> resolve(ScannedCode code) {
    final actions = <ScanAction>[];

    switch (code.kind) {
      case ScannedCodeKind.url:
        actions.add(_urlAction(code));
      case ScannedCodeKind.wifi:
        actions.addAll(_wifiActions(code));
      case ScannedCodeKind.phone:
        actions.add(
          _targetAction(ScanActionType.dial, 'tel', code.displayValue),
        );
        actions.add(
          _targetAction(ScanActionType.sms, 'sms', code.displayValue),
        );
      case ScannedCodeKind.email:
        actions.add(
          _targetAction(ScanActionType.email, 'mailto', code.displayValue),
        );
      case ScannedCodeKind.sms:
        actions.add(
          _targetAction(ScanActionType.sms, 'sms', code.displayValue),
        );
      case ScannedCodeKind.geo:
        actions.add(
          _targetAction(ScanActionType.showOnMap, 'geo', code.displayValue),
        );
      case ScannedCodeKind.contact:
      case ScannedCodeKind.calendar:
      case ScannedCodeKind.text:
        // Nothing beyond copying and saving. A contact card could be handed
        // to the contacts app, but that means writing a file out for another
        // app to read, and the value does not pay for the extra surface.
        break;
    }

    actions.add(_copyAction(code));
    actions.add(_saveToNotesAction(code));
    return actions;
  }

  ScanAction _urlAction(ScannedCode code) {
    final raw = code.displayValue.trim();
    if (raw.isEmpty) {
      return const ScanAction.blocked(
        ScanActionType.openUrl,
        ScanBlockReason.malformedTarget,
      );
    }
    if (raw.length > AppConstants.scanMaxPayloadLength) {
      return const ScanAction.blocked(
        ScanActionType.openUrl,
        ScanBlockReason.payloadTooLong,
      );
    }

    // A bare domain gets `https://` in front of it, never `http://`. If the
    // site does not do HTTPS the browser will say so; guessing downwards on
    // the user's behalf is not this app's call to make.
    final candidate = raw.contains('://') ? raw : 'https://$raw';

    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      return const ScanAction.blocked(
        ScanActionType.openUrl,
        ScanBlockReason.malformedTarget,
      );
    }
    if (!AppConstants.scanLaunchableSchemes.contains(
      uri.scheme.toLowerCase(),
    )) {
      return const ScanAction.blocked(
        ScanActionType.openUrl,
        ScanBlockReason.unsupportedScheme,
      );
    }

    return ScanAction.allowed(ScanActionType.openUrl, uri.toString());
  }

  List<ScanAction> _wifiActions(ScannedCode code) {
    final wifi = code.wifi;
    if (wifi == null || !wifi.isUsable) {
      return const <ScanAction>[
        ScanAction.blocked(
          ScanActionType.connectWifi,
          ScanBlockReason.incompleteWifi,
        ),
      ];
    }

    return <ScanAction>[
      ScanAction.allowed(ScanActionType.connectWifi, wifi.ssid),
      if (wifi.security.needsPassword)
        ScanAction.allowed(ScanActionType.copyWifiPassword, wifi.password),
    ];
  }

  /// Builds a `scheme:value` action after checking the scheme and the value.
  ScanAction _targetAction(ScanActionType type, String scheme, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return ScanAction.blocked(type, ScanBlockReason.malformedTarget);
    }
    if (!AppConstants.scanLaunchableSchemes.contains(scheme)) {
      return ScanAction.blocked(type, ScanBlockReason.unsupportedScheme);
    }

    // A newline or a second scheme inside the value is how an injected intent
    // would try to get through, so a value carrying either is refused.
    if (trimmed.contains('\n') ||
        trimmed.contains('\r') ||
        trimmed.contains('://')) {
      return ScanAction.blocked(type, ScanBlockReason.malformedTarget);
    }

    return ScanAction.allowed(type, '$scheme:${Uri.encodeComponent(trimmed)}');
  }

  ScanAction _copyAction(ScannedCode code) {
    if (code.rawValue.length > AppConstants.scanMaxPayloadLength) {
      return const ScanAction.blocked(
        ScanActionType.copy,
        ScanBlockReason.payloadTooLong,
      );
    }
    if (code.rawValue.isEmpty) {
      return const ScanAction.blocked(
        ScanActionType.copy,
        ScanBlockReason.malformedTarget,
      );
    }
    return ScanAction.allowed(ScanActionType.copy, code.rawValue);
  }

  ScanAction _saveToNotesAction(ScannedCode code) {
    if (code.rawValue.trim().isEmpty) {
      return const ScanAction.blocked(
        ScanActionType.saveToNotes,
        ScanBlockReason.malformedTarget,
      );
    }
    if (code.rawValue.length > AppConstants.notesMaxLength) {
      return const ScanAction.blocked(
        ScanActionType.saveToNotes,
        ScanBlockReason.payloadTooLong,
      );
    }
    return ScanAction.allowed(ScanActionType.saveToNotes, code.rawValue);
  }
}
