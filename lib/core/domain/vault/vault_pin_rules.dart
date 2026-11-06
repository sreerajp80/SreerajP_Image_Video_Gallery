import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Why a PIN was refused.
///
/// A reason, not a sentence: the screen turns it into a localised message, so
/// nothing here has to be translated and nothing here is a raw UI string.
enum VaultPinRejection {
  /// Nothing was typed.
  empty,

  /// Fewer digits than the vault accepts.
  tooShort,

  /// More digits than the vault accepts.
  tooLong,

  /// Something other than digits was typed.
  notDigits,

  /// Every digit is the same, e.g. `0000`.
  allSameDigit,

  /// A straight run up or down, e.g. `1234` or `9876`.
  sequential,
}

/// The rules every vault PIN has to pass.
///
/// Pure and static, so the whole set is unit tested without a keystore, a
/// store, or a widget. The weak-PIN checks are deliberately narrow: they turn
/// away the handful of PINs an opportunist tries first, and nothing else. A
/// longer blocklist would only push people towards writing their PIN down.
class VaultPinRules {
  VaultPinRules._();

  /// The rejection reason for [pin], or null when it is acceptable.
  static VaultPinRejection? validate(String pin) {
    if (pin.isEmpty) return VaultPinRejection.empty;
    if (!_isAllDigits(pin)) return VaultPinRejection.notDigits;
    if (pin.length < AppConstants.vaultPinMinLength) {
      return VaultPinRejection.tooShort;
    }
    if (pin.length > AppConstants.vaultPinMaxLength) {
      return VaultPinRejection.tooLong;
    }
    if (_isAllSameDigit(pin)) return VaultPinRejection.allSameDigit;
    if (_isSequential(pin)) return VaultPinRejection.sequential;
    return null;
  }

  /// Whether [pin] passes every rule.
  static bool isValid(String pin) => validate(pin) == null;

  /// Whether [pin] is long enough to be worth checking as the user types.
  ///
  /// The pad uses this to know when to enable its confirm button; it is not a
  /// substitute for [validate].
  static bool isCompleteLength(String pin) =>
      pin.length >= AppConstants.vaultPinMinLength &&
      pin.length <= AppConstants.vaultPinMaxLength;

  static bool _isAllDigits(String value) {
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) return false;
    }
    return true;
  }

  static bool _isAllSameDigit(String value) {
    final first = value.codeUnitAt(0);
    for (var i = 1; i < value.length; i++) {
      if (value.codeUnitAt(i) != first) return false;
    }
    return true;
  }

  /// Whether every step is +1 or every step is -1.
  static bool _isSequential(String value) {
    if (value.length < 2) return false;
    final step = value.codeUnitAt(1) - value.codeUnitAt(0);
    if (step != 1 && step != -1) return false;
    for (var i = 2; i < value.length; i++) {
      if (value.codeUnitAt(i) - value.codeUnitAt(i - 1) != step) return false;
    }
    return true;
  }
}
