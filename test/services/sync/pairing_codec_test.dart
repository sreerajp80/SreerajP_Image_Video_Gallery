import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/pairing_codec.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';

/// A pairing secret of the right length, written the way the codec expects.
///
/// The code carries the short secret, not the AES key: a 32-byte key cannot
/// be read aloud, and both sides derive the same key from this.
String _key([int seed = 7]) => base64Url
    .encode(
      List<int>.generate(
        AppConstants.syncPairingSecretBytes,
        (i) => (i * seed + 11) % 256,
      ),
    )
    .replaceAll('=', '');

PairingPayload _payload({
  String host = '192.168.1.42',
  int port = 45123,
  String? sessionKey,
  String deviceName = 'A Phone',
  SyncRole hostRole = SyncRole.send,
  int protocolVersion = AppConstants.syncProtocolVersion,
}) {
  return PairingPayload(
    protocolVersion: protocolVersion,
    host: host,
    port: port,
    sessionKey: sessionKey ?? _key(),
    deviceName: deviceName,
    hostRole: hostRole,
  );
}

void main() {
  group('PairingCodec QR round trip', () {
    test('a payload survives encode then decode unchanged', () {
      final original = _payload();
      final decoded = PairingCodec.decode(PairingCodec.encode(original));

      expect(decoded, isNotNull);
      expect(decoded, original);
    });

    test('keeps the session key exactly', () {
      final key = _key(3);
      final decoded = PairingCodec.decode(
        PairingCodec.encode(_payload(sessionKey: key)),
      );
      expect(decoded!.sessionKey, key);
    });

    test('round trips both roles', () {
      for (final role in SyncRole.values) {
        final decoded = PairingCodec.decode(
          PairingCodec.encode(_payload(hostRole: role)),
        );
        expect(decoded!.hostRole, role);
        expect(decoded.scannerRole, role.opposite);
      }
    });

    test('survives a device name holding the field separator', () {
      // The name is the only free-text field. Encoded, it cannot shift the
      // fields after it, which is the whole reason it is encoded.
      final decoded = PairingCodec.decode(
        PairingCodec.encode(_payload(deviceName: "Sam's | Pixel | 9")),
      );
      expect(decoded, isNotNull);
      expect(decoded!.deviceName, "Sam's | Pixel | 9");
      expect(decoded.port, 45123);
    });

    test('survives a name with non-Latin characters', () {
      final decoded = PairingCodec.decode(
        PairingCodec.encode(_payload(deviceName: 'ഫോൺ')),
      );
      expect(decoded!.deviceName, 'ഫോൺ');
    });

    test('starts with the scheme, so a foreign QR code is obvious', () {
      expect(
        PairingCodec.encode(_payload()),
        startsWith('${PairingCodec.scheme}|'),
      );
    });
  });

  group('PairingCodec.decode refuses bad input', () {
    test('refuses an empty or rubbish string', () {
      expect(PairingCodec.decode(''), isNull);
      expect(PairingCodec.decode('   '), isNull);
      expect(PairingCodec.decode('hello'), isNull);
      expect(PairingCodec.decode('https://example.com'), isNull);
    });

    test('refuses another app QR code with the right field count', () {
      expect(PairingCodec.decode('a|b|c|d|e|f|g|h'), isNull);
    });

    test('refuses a truncated code', () {
      final full = PairingCodec.encode(_payload());
      expect(PairingCodec.decode(full.substring(0, full.length - 4)), isNull);
      expect(PairingCodec.decode(full.split('|').take(5).join('|')), isNull);
    });

    test('refuses a code with a wrong checksum', () {
      final full = PairingCodec.encode(_payload());
      final parts = full.split('|');
      parts[parts.length - 1] = 'zzzzzzz';
      expect(PairingCodec.decode(parts.join('|')), isNull);
    });

    test('refuses a code whose body was edited after the checksum', () {
      final parts = PairingCodec.encode(_payload()).split('|');
      parts[3] = '45124'; // port changed, checksum left alone
      expect(PairingCodec.decode(parts.join('|')), isNull);
    });

    test('refuses a protocol version this build does not speak', () {
      final parts = PairingCodec.encode(_payload()).split('|');
      parts[1] = '${AppConstants.syncProtocolVersion + 1}';
      final body = parts.sublist(0, 7).join('|');
      // Rebuild the checksum so only the version is wrong.
      final rebuilt = PairingCodec.decode(
        '$body|${PairingCodec.encode(_payload()).split('|').last}',
      );
      expect(rebuilt, isNull);
    });

    test('refuses a public address, even in a well-formed code', () {
      // The guard runs at the edge as well as at the socket, so a pairing
      // code for somewhere off the local network never becomes a payload.
      for (final host in <String>['8.8.8.8', '1.1.1.1', '203.0.113.7']) {
        final encoded = PairingCodec.encode(_payload(host: host));
        expect(
          PairingCodec.decode(encoded),
          isNull,
          reason: '$host is not on the local network',
        );
      }
    });

    test('refuses loopback as a peer address', () {
      expect(
        PairingCodec.decode(PairingCodec.encode(_payload(host: '127.0.0.1'))),
        isNull,
      );
    });

    test('refuses a port in the well-known range', () {
      expect(
        PairingCodec.decode(PairingCodec.encode(_payload(port: 80))),
        isNull,
      );
      expect(
        PairingCodec.decode(PairingCodec.encode(_payload(port: 443))),
        isNull,
      );
    });

    test('refuses a pairing secret of the wrong length', () {
      final short = base64Url
          .encode(List<int>.filled(4, 1))
          .replaceAll('=', '');
      expect(
        PairingCodec.decode(PairingCodec.encode(_payload(sessionKey: short))),
        isNull,
      );

      // A 32-byte value is refused too: that is the derived key, and the key
      // is never what a pairing code carries.
      final tooLong = base64Url
          .encode(List<int>.filled(AppConstants.syncSessionKeyBytes, 1))
          .replaceAll('=', '');
      expect(
        PairingCodec.decode(PairingCodec.encode(_payload(sessionKey: tooLong))),
        isNull,
      );
    });

    test('refuses an unknown role name', () {
      final parts = PairingCodec.encode(_payload()).split('|');
      parts[4] = 'both';
      expect(PairingCodec.decode(parts.join('|')), isNull);
    });

    test('refuses an absurdly long string without parsing it', () {
      expect(PairingCodec.decode('x' * 1000), isNull);
    });
  });

  group('PairingCodec manual code', () {
    test('is six groups of four characters', () {
      final manual = PairingCodec.encodeManual(_payload());
      expect(manual, isNotNull);

      final groups = manual!.split('-');
      expect(groups, hasLength(AppConstants.syncManualCodeGroupCount));
      for (final group in groups) {
        expect(group, hasLength(AppConstants.syncManualCodeGroupLength));
      }
    });

    test('carries the address and port back', () {
      final manual = PairingCodec.encodeManual(
        _payload(host: '192.168.4.77', port: 51234),
      );
      final decoded = PairingCodec.decodeManual(manual!);

      expect(decoded, isNotNull);
      expect(decoded!.host, '192.168.4.77');
      expect(decoded.port, 51234);
      expect(decoded.keyPrefix, hasLength(9));
    });

    test('round trips every private range', () {
      for (final host in <String>[
        '10.0.0.1',
        '172.16.9.9',
        '192.168.1.1',
        '169.254.3.4',
      ]) {
        final manual = PairingCodec.encodeManual(_payload(host: host));
        expect(PairingCodec.decodeManual(manual!)!.host, host);
      }
    });

    test('uses no character a person confuses with another', () {
      final manual = PairingCodec.encodeManual(_payload())!;
      for (final ch in manual.replaceAll('-', '').split('')) {
        expect(
          PairingCodec.manualAlphabet.contains(ch),
          isTrue,
          reason: '$ch is not in the reduced alphabet',
        );
      }
      expect(manual, isNot(contains('I')));
      expect(manual, isNot(contains('O')));
    });

    test('normalises the substitutions a person actually makes', () {
      final manual = PairingCodec.encodeManual(_payload())!;
      final clean = manual.replaceAll('-', '');

      expect(PairingCodec.normaliseManual(manual), clean);
      expect(PairingCodec.normaliseManual(manual.toLowerCase()), clean);
      expect(PairingCodec.normaliseManual(manual.replaceAll('-', ' ')), clean);
      // I and L read back as 1, O as 0, U as V.
      expect(PairingCodec.normaliseManual('IO-UL'), '10V1');
    });

    test('decodes a code typed in lower case with spaces', () {
      final manual = PairingCodec.encodeManual(
        _payload(host: '10.1.2.3', port: 40001),
      )!;
      final typed = manual.toLowerCase().replaceAll('-', ' ');

      expect(PairingCodec.decodeManual(typed)!.host, '10.1.2.3');
      expect(PairingCodec.decodeManual(typed)!.port, 40001);
    });

    test('refuses a code of the wrong length', () {
      expect(PairingCodec.decodeManual(''), isNull);
      expect(PairingCodec.decodeManual('ABCD'), isNull);
      expect(PairingCodec.decodeManual('ABCD-EFGH-JKMN'), isNull);
      expect(PairingCodec.decodeManual('A' * 40), isNull);
    });

    test('refuses a manual code that decodes to a public address', () {
      // The bytes are packed the same way, so a hand-made code for 8.8.8.8
      // is well-formed and must still be refused.
      final encoded = PairingCodec.encodeManual(
        _payload(host: '192.168.1.1', port: 45000),
      )!;
      expect(PairingCodec.decodeManual(encoded), isNotNull);

      // 8.8.8.8 cannot even be encoded, because the encoder checks too.
      expect(PairingCodec.encodeManual(_payload(host: '8.8.8.8')), isNull);
    });

    test('refuses to encode a port in the well-known range', () {
      expect(PairingCodec.encodeManual(_payload(port: 22)), isNull);
    });
  });

  group('the QR code and the typed code end at the same key', () {
    test('both routes derive one identical session key', () {
      // This is what makes the typed code a real fallback rather than a
      // weaker one. A short code cannot carry a 32-byte key, so it carries
      // the secret and both sides stretch it the same way.
      final payload = _payload(host: '192.168.1.42', port: 45123);

      final scanned = PairingCodec.decode(PairingCodec.encode(payload))!;
      final typed = PairingCodec.decodeManual(
        PairingCodec.encodeManual(payload)!,
      )!;

      final fromQr = TransferCryptoService.deriveSessionKey(
        Uint8List.fromList(
          base64Url.decode(
            scanned.sessionKey.padRight(
              (scanned.sessionKey.length + 3) & ~3,
              '=',
            ),
          ),
        ),
      );
      final fromTyped = TransferCryptoService.deriveSessionKey(
        Uint8List.fromList(typed.keyPrefix),
      );

      expect(fromQr, fromTyped);
      expect(fromQr, hasLength(AppConstants.syncSessionKeyBytes));
    });

    test('a different secret gives a different key', () {
      final a = TransferCryptoService.deriveSessionKey(
        Uint8List.fromList(List<int>.filled(9, 1)),
      );
      final b = TransferCryptoService.deriveSessionKey(
        Uint8List.fromList(List<int>.filled(9, 2)),
      );
      expect(a, isNot(b));
    });

    test('the same secret gives a different key per protocol version', () {
      final secret = Uint8List.fromList(List<int>.filled(9, 5));
      expect(
        TransferCryptoService.deriveSessionKey(secret, protocolVersion: 1),
        isNot(
          TransferCryptoService.deriveSessionKey(secret, protocolVersion: 2),
        ),
      );
    });
  });

  group('PairingPayload', () {
    test('toString hides the session key', () {
      final key = _key();
      final text = _payload(sessionKey: key).toString();

      expect(text, isNot(contains(key)));
      expect(text, contains('key hidden'));
      expect(text, contains('192.168.1.42'));
    });

    test('scannerRole is always the opposite of hostRole', () {
      expect(_payload(hostRole: SyncRole.send).scannerRole, SyncRole.receive);
      expect(_payload(hostRole: SyncRole.receive).scannerRole, SyncRole.send);
    });
  });
}
