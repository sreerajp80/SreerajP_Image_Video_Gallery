import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/barcode_payload_parser.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/scan_action_resolver.dart';

const _parser = BarcodePayloadParser();
const _resolver = ScanActionResolver();

List<ScanAction> _actionsFor(String payload) =>
    _resolver.resolve(_parser.parse(payload));

ScanAction? _find(List<ScanAction> actions, ScanActionType type) {
  for (final action in actions) {
    if (action.type == type) return action;
  }
  return null;
}

void main() {
  group('every code can be copied', () {
    test('a plain text code offers copy and save, and nothing else', () {
      final actions = _actionsFor('just some words');
      expect(
        actions.map((action) => action.type),
        containsAll(<ScanActionType>[
          ScanActionType.copy,
          ScanActionType.saveToNotes,
        ]),
      );
      expect(_find(actions, ScanActionType.openUrl), isNull);
      expect(_find(actions, ScanActionType.dial), isNull);
    });

    test('copy carries the raw payload, not the tidied one', () {
      final code = _parser.parse('  https://example.com  ');
      final copy = _find(_resolver.resolve(code), ScanActionType.copy);
      expect(copy?.target, '  https://example.com  ');
    });

    test('an empty payload cannot be copied', () {
      final copy = _find(_actionsFor(''), ScanActionType.copy);
      expect(copy?.isAllowed, isFalse);
      expect(copy?.blockReason, ScanBlockReason.malformedTarget);
    });
  });

  group('only listed schemes may be launched', () {
    test('an https address may be opened', () {
      final open = _find(
        _actionsFor('https://example.com/page'),
        ScanActionType.openUrl,
      );
      expect(open?.isAllowed, isTrue);
      expect(open?.target, 'https://example.com/page');
    });

    test('a bare domain is opened as https, never http', () {
      final open = _find(_actionsFor('example.com'), ScanActionType.openUrl);
      expect(open?.isAllowed, isTrue);
      expect(open?.target, startsWith('https://'));
    });

    // The whole point of the resolver. If any of these ever becomes openable,
    // the app has handed a hostile intent to another app on a user's tap.
    test('a dangerous scheme is never openable', () {
      const payloads = <String>[
        'javascript:alert(1)',
        'file:///etc/passwd',
        'content://media/external/images/1',
        'intent://scan/#Intent;scheme=x;end',
        'jar:file:///x.jar!/',
        'data:text/html,<script>x</script>',
      ];

      for (final payload in payloads) {
        final actions = _actionsFor(payload);
        final open = _find(actions, ScanActionType.openUrl);
        expect(
          open == null || !open.isAllowed,
          isTrue,
          reason: '$payload must never be openable',
        );
      }
    });

    test('a url with no host is refused', () {
      final code = _parser
          .parse('https://example.com')
          .copyWith(displayValue: 'https://');
      final open = _find(_resolver.resolve(code), ScanActionType.openUrl);
      expect(open?.isAllowed, isFalse);
      expect(open?.blockReason, ScanBlockReason.malformedTarget);
    });

    test('a url past the cap is refused rather than opened', () {
      final long =
          'https://example.com/${'a' * AppConstants.scanMaxPayloadLength}';
      final code = _parser
          .parse('https://example.com')
          .copyWith(displayValue: long);
      final open = _find(_resolver.resolve(code), ScanActionType.openUrl);
      expect(open?.isAllowed, isFalse);
      expect(open?.blockReason, ScanBlockReason.payloadTooLong);
    });
  });

  group('phone, message, mail and map', () {
    test('a phone number can be dialled and messaged', () {
      final actions = _actionsFor('tel:+914712345678');
      final dial = _find(actions, ScanActionType.dial);
      expect(dial?.isAllowed, isTrue);
      expect(dial?.target, startsWith('tel:'));
      expect(_find(actions, ScanActionType.sms)?.isAllowed, isTrue);
    });

    test('an email address can be written to', () {
      final email = _find(
        _actionsFor('mailto:a@example.com'),
        ScanActionType.email,
      );
      expect(email?.isAllowed, isTrue);
      expect(email?.target, startsWith('mailto:'));
    });

    test('a map point can be shown', () {
      final map = _find(
        _actionsFor('geo:8.5241,76.9366'),
        ScanActionType.showOnMap,
      );
      expect(map?.isAllowed, isTrue);
      expect(map?.target, startsWith('geo:'));
    });

    test('a value carrying its own scheme is refused', () {
      final code = _parser
          .parse('tel:+911234567')
          .copyWith(displayValue: 'https://evil.example');
      final dial = _find(_resolver.resolve(code), ScanActionType.dial);
      expect(dial?.isAllowed, isFalse);
      expect(dial?.blockReason, ScanBlockReason.malformedTarget);
    });

    test('a value carrying a newline is refused', () {
      final code = _parser
          .parse('tel:+911234567')
          .copyWith(displayValue: '123\nDIAL');
      final dial = _find(_resolver.resolve(code), ScanActionType.dial);
      expect(dial?.isAllowed, isFalse);
    });

    test('the target is encoded, so a hash cannot cut the number short', () {
      final code = _parser
          .parse('tel:+911234567')
          .copyWith(displayValue: '123#456');
      final dial = _find(_resolver.resolve(code), ScanActionType.dial);
      expect(dial?.isAllowed, isTrue);
      expect(dial?.target, isNot(contains('#')));
    });
  });

  group('wifi', () {
    test('a complete code offers connect and copying the password', () {
      final actions = _actionsFor('WIFI:T:WPA;S:HomeNet;P:secret123;;');
      final connect = _find(actions, ScanActionType.connectWifi);
      expect(connect?.isAllowed, isTrue);
      expect(connect?.target, 'HomeNet');

      final copyPassword = _find(actions, ScanActionType.copyWifiPassword);
      expect(copyPassword?.isAllowed, isTrue);
      expect(copyPassword?.target, 'secret123');
    });

    test('an open network offers no password to copy', () {
      final actions = _actionsFor('WIFI:T:nopass;S:FreeWifi;;');
      expect(_find(actions, ScanActionType.connectWifi)?.isAllowed, isTrue);
      expect(_find(actions, ScanActionType.copyWifiPassword), isNull);
    });

    test('an incomplete code is blocked with a reason', () {
      final connect = _find(
        _actionsFor('WIFI:T:WPA;S:Net;;'),
        ScanActionType.connectWifi,
      );
      expect(connect?.isAllowed, isFalse);
      expect(connect?.blockReason, ScanBlockReason.incompleteWifi);
    });
  });

  group('saving to notes', () {
    test('ordinary text can be saved', () {
      final save = _find(_actionsFor('a note'), ScanActionType.saveToNotes);
      expect(save?.isAllowed, isTrue);
    });

    test('text past the note cap cannot be saved', () {
      final code = _parser
          .parse('x')
          .copyWith(rawValue: 'x' * (AppConstants.notesMaxLength + 1));
      final save = _find(_resolver.resolve(code), ScanActionType.saveToNotes);
      expect(save?.isAllowed, isFalse);
      expect(save?.blockReason, ScanBlockReason.payloadTooLong);
    });
  });

  test('a blocked action is still offered, so the screen can explain it', () {
    final actions = _actionsFor('WIFI:T:WPA;S:Net;;');
    expect(actions.any((action) => !action.isAllowed), isTrue);
  });
}
