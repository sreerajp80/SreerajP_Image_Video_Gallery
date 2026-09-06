import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_rules.dart';

void main() {
  group('VaultPinRules', () {
    group('accepts', () {
      test('an ordinary PIN at the shortest allowed length', () {
        expect(VaultPinRules.validate('1937'), isNull);
        expect(VaultPinRules.isValid('1937'), isTrue);
      });

      test('a PIN at the longest allowed length', () {
        expect(VaultPinRules.isValid('19370462'), isTrue);
      });

      test('a PIN that only looks like a run', () {
        // Steps of +1 then -1: not a straight run, so it stands.
        expect(VaultPinRules.isValid('1232'), isTrue);
        // Two apart each step is a pattern, but not the one being blocked.
        expect(VaultPinRules.isValid('1357'), isTrue);
      });

      test('a PIN with a repeated digit that is not all the same', () {
        expect(VaultPinRules.isValid('1131'), isTrue);
      });
    });

    group('rejects', () {
      test('nothing typed', () {
        expect(VaultPinRules.validate(''), VaultPinRejection.empty);
      });

      test('a PIN that is too short', () {
        expect(VaultPinRules.validate('193'), VaultPinRejection.tooShort);
      });

      test('a PIN that is too long', () {
        expect(VaultPinRules.validate('193704621'), VaultPinRejection.tooLong);
      });

      test('anything that is not a digit', () {
        expect(VaultPinRules.validate('19a7'), VaultPinRejection.notDigits);
        expect(VaultPinRules.validate('19 7'), VaultPinRejection.notDigits);
        expect(VaultPinRules.validate('19.7'), VaultPinRejection.notDigits);
        // Checked before the length, so a short non-digit says the useful
        // thing rather than complaining about length first.
        expect(VaultPinRules.validate('ab'), VaultPinRejection.notDigits);
      });

      test('one digit all the way through', () {
        expect(VaultPinRules.validate('0000'), VaultPinRejection.allSameDigit);
        expect(
          VaultPinRules.validate('77777777'),
          VaultPinRejection.allSameDigit,
        );
      });

      test('a straight run in either direction', () {
        expect(VaultPinRules.validate('1234'), VaultPinRejection.sequential);
        expect(VaultPinRules.validate('4321'), VaultPinRejection.sequential);
        expect(
          VaultPinRules.validate('23456789'),
          VaultPinRejection.sequential,
        );
        expect(
          VaultPinRules.validate('98765432'),
          VaultPinRejection.sequential,
        );
      });
    });

    group('isCompleteLength', () {
      test('is true only inside the allowed range', () {
        expect(
          VaultPinRules.isCompleteLength(
            '9' * (AppConstants.vaultPinMinLength - 1),
          ),
          isFalse,
        );
        expect(
          VaultPinRules.isCompleteLength('9' * AppConstants.vaultPinMinLength),
          isTrue,
        );
        expect(
          VaultPinRules.isCompleteLength('9' * AppConstants.vaultPinMaxLength),
          isTrue,
        );
        expect(
          VaultPinRules.isCompleteLength(
            '9' * (AppConstants.vaultPinMaxLength + 1),
          ),
          isFalse,
        );
      });

      test('says nothing about whether the PIN is acceptable', () {
        // Long enough to submit, still refused by the rules. The pad uses this
        // only to know when to enable its button.
        expect(VaultPinRules.isCompleteLength('1234'), isTrue);
        expect(VaultPinRules.isValid('1234'), isFalse);
      });
    });
  });
}
