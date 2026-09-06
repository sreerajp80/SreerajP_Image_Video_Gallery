import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';

/// Why reading text out of a picture did not work.
///
/// A reason, not a message. The screen turns it into localised text.
enum OcrFailure {
  /// The picture could not be found or opened.
  unreadableImage,

  /// The picture is larger than the reader will take on.
  imageTooLarge,

  /// The language files are missing from the app.
  missingLanguageData,

  /// The reader took too long and was given up on.
  timedOut,

  /// The reader failed for some other reason.
  engineFailed,
}

/// What one pass of the text reader came to.
///
/// A picture with no text in it is a success with empty text, not a failure.
/// The two are different things and the screen says something different for
/// each.
class OcrResult {
  /// The text, cleaned up and in reading order.
  final String text;

  /// The same text split into lines, with blank ones dropped.
  final List<String> lines;

  /// Which language setting produced it.
  final OcrLanguage language;

  /// How long the pass took.
  final Duration duration;

  /// Why it failed, or null when it worked.
  final OcrFailure? failure;

  const OcrResult({
    this.text = '',
    this.lines = const <String>[],
    this.language = OcrLanguage.english,
    this.duration = Duration.zero,
    this.failure,
  });

  /// A pass that could not run.
  const OcrResult.failed(this.failure, {required this.language})
    : text = '',
      lines = const <String>[],
      duration = Duration.zero;

  /// Whether the pass failed.
  bool get isFailure => failure != null;

  /// Whether the pass worked but the picture held no text.
  bool get foundNothing => failure == null && text.trim().isEmpty;

  /// Whether there is text to show.
  bool get hasText => failure == null && text.trim().isNotEmpty;

  /// How many characters were read.
  int get characterCount => text.length;

  /// How many words were read.
  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  OcrResult copyWith({
    String? text,
    List<String>? lines,
    OcrLanguage? language,
    Duration? duration,
    OcrFailure? failure,
  }) {
    return OcrResult(
      text: text ?? this.text,
      lines: lines ?? this.lines,
      language: language ?? this.language,
      duration: duration ?? this.duration,
      failure: failure ?? this.failure,
    );
  }

  /// Names the size of the result, never the text itself.
  ///
  /// Text read out of someone's photo can be anything at all: a payslip, a
  /// prescription, a letter. It does not go into a log line.
  @override
  String toString() =>
      'OcrResult(${language.code}, $characterCount chars, '
      'failure: ${failure?.name})';
}
