/// A language the text reader can be pointed at.
///
/// The codes are Tesseract's own, and they name the `.traineddata` files
/// shipped in `assets/tessdata/`. Adding a language here means shipping
/// another file, so the list is short on purpose.
enum OcrLanguage {
  /// English only. Fastest, and right for most screenshots.
  english(code: 'eng'),

  /// Malayalam only.
  malayalam(code: 'mal'),

  /// Both at once, for a page that mixes the two.
  ///
  /// Slower than either alone, and a little more likely to misread a letter,
  /// because the reader has two alphabets to choose between for every shape.
  /// It is not the default for that reason.
  both(code: 'eng+mal');

  /// What Tesseract is told.
  final String code;

  const OcrLanguage({required this.code});

  /// The traineddata files this choice needs.
  List<String> get requiredFiles => code
      .split('+')
      .map((part) => '$part.traineddata')
      .toList(growable: false);
}
