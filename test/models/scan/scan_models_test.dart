import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';

void main() {
  group('ScannedCode', () {
    const code = ScannedCode(
      rawValue: 'https://example.com',
      kind: ScannedCodeKind.url,
      displayValue: 'https://example.com',
      format: 'qrCode',
    );

    test('two codes with the same parts are equal', () {
      expect(
        code,
        const ScannedCode(
          rawValue: 'https://example.com',
          kind: ScannedCodeKind.url,
          displayValue: 'https://example.com',
          format: 'qrCode',
        ),
      );
      expect(code.hashCode, isNotNull);
    });

    test('a different payload is a different code', () {
      expect(code, isNot(code.copyWith(rawValue: 'https://other.example')));
    });

    test('copyWith changes only what it is given', () {
      final changed = code.copyWith(format: 'aztec');
      expect(changed.format, 'aztec');
      expect(changed.rawValue, code.rawValue);
      expect(changed.kind, code.kind);
    });

    // A code can hold a password or a private address, and toString is the
    // string most likely to reach a log by accident.
    test('toString never prints the payload', () {
      const secret = ScannedCode(
        rawValue: 'WIFI:T:WPA;S:Home;P:hunter2;;',
        kind: ScannedCodeKind.wifi,
        displayValue: 'Home',
      );

      expect(secret.toString(), isNot(contains('hunter2')));
      expect(secret.toString(), isNot(contains('Home')));
      expect(secret.toString(), contains('wifi'));
    });

    test('every kind but text says it has an action', () {
      for (final kind in ScannedCodeKind.values) {
        expect(kind.hasAction, kind != ScannedCodeKind.text, reason: kind.name);
      }
    });
  });

  group('WifiCredentials', () {
    test('a WPA network needs a password to be usable', () {
      const withoutPassword = WifiCredentials(ssid: 'Net');
      const withPassword = WifiCredentials(ssid: 'Net', password: 'secret');

      expect(withoutPassword.isUsable, isFalse);
      expect(withPassword.isUsable, isTrue);
    });

    test('an open network is usable with no password', () {
      const open = WifiCredentials(ssid: 'Cafe', security: WifiSecurity.open);
      expect(open.isUsable, isTrue);
    });

    test('a network with no name is never usable', () {
      const nameless = WifiCredentials(ssid: '', password: 'secret');
      expect(nameless.isUsable, isFalse);
    });

    test('only the open kind needs no password', () {
      for (final security in WifiSecurity.values) {
        expect(
          security.needsPassword,
          security != WifiSecurity.open,
          reason: security.name,
        );
      }
    });

    test('equality covers every field', () {
      const base = WifiCredentials(ssid: 'A', password: 'b');
      expect(base, const WifiCredentials(ssid: 'A', password: 'b'));
      expect(base, isNot(base.copyWith(isHidden: true)));
      expect(base, isNot(base.copyWith(password: 'c')));
    });

    test('toString never prints the password', () {
      const wifi = WifiCredentials(ssid: 'Home', password: 'hunter2');
      expect(wifi.toString(), isNot(contains('hunter2')));
      expect(wifi.toString(), contains('Home'));
    });
  });

  group('ScanAction', () {
    test('an allowed action carries its target', () {
      const action = ScanAction.allowed(
        ScanActionType.openUrl,
        'https://example.com',
      );

      expect(action.isAllowed, isTrue);
      expect(action.blockReason, isNull);
      expect(action.target, 'https://example.com');
    });

    test('a blocked action carries a reason and no target', () {
      const action = ScanAction.blocked(
        ScanActionType.openUrl,
        ScanBlockReason.unsupportedScheme,
      );

      expect(action.isAllowed, isFalse);
      expect(action.blockReason, ScanBlockReason.unsupportedScheme);
      expect(action.target, isEmpty);
    });

    test('equality covers the reason', () {
      const one = ScanAction.blocked(
        ScanActionType.copy,
        ScanBlockReason.payloadTooLong,
      );
      const other = ScanAction.blocked(
        ScanActionType.copy,
        ScanBlockReason.malformedTarget,
      );

      expect(one, isNot(other));
    });
  });
}
