import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Why a tag name was refused.
enum TagNameError {
  /// Nothing but spaces was typed.
  empty,

  /// Longer than the allowed length.
  tooLong,

  /// A tag with this name already exists.
  duplicate,
}

/// The result of checking a tag name.
class TagNameCheck {
  /// The cleaned-up name, ready to store. Empty when [error] is set.
  final String normalized;

  /// What was wrong, or null when the name is fine.
  final TagNameError? error;

  const TagNameCheck({required this.normalized, this.error});

  bool get isValid => error == null;
}

/// The rules every tag name has to follow.
///
/// Pure, so the same rules can be checked live while the user types and again
/// before anything is written, with no chance of the two disagreeing.
class TagNameRules {
  const TagNameRules._();

  /// Longest a tag name may be.
  static const int maxLength = AppConstants.tagNameMaxLength;

  /// Trims the ends and collapses runs of inner whitespace into one space.
  ///
  /// So `"  beach   holiday "` and `"beach holiday"` are the same tag, which
  /// is what a user expects and what stops near-identical tags piling up.
  static String normalize(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// True when the two names mean the same tag.
  ///
  /// Case is ignored, so `Beach` and `beach` are one tag, matching the
  /// case-insensitive lookup the tag table uses.
  static bool isSameName(String a, String b) =>
      normalize(a).toLowerCase() == normalize(b).toLowerCase();

  /// Checks [name] against the rules.
  ///
  /// [existingNames] is every name already in use. When [ignoreName] is
  /// given, that one name is allowed to match, which is what a rename needs
  /// so a tag can keep its own name while only its letter case changes.
  static TagNameCheck check(
    String name, {
    Iterable<String> existingNames = const <String>[],
    String? ignoreName,
  }) {
    final normalized = normalize(name);

    if (normalized.isEmpty) {
      return const TagNameCheck(normalized: '', error: TagNameError.empty);
    }
    if (normalized.length > maxLength) {
      return TagNameCheck(normalized: normalized, error: TagNameError.tooLong);
    }

    for (final existing in existingNames) {
      if (ignoreName != null && isSameName(existing, ignoreName)) continue;
      if (isSameName(existing, normalized)) {
        return TagNameCheck(
          normalized: normalized,
          error: TagNameError.duplicate,
        );
      }
    }

    return TagNameCheck(normalized: normalized);
  }
}
