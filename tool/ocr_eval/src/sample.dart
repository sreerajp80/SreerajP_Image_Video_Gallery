import 'dart:io';

/// One test picture and the correct text for it.
///
/// Used by the OCR accuracy tool only; it is not part of the app.
class Sample {
  /// File name without its extension, for example `ml_newspaper_03`.
  final String name;

  /// The picture.
  final File image;

  /// The correct text, typed and checked by hand.
  final File truth;

  const Sample({required this.name, required this.image, required this.truth});

  /// The group used in the report: the first two parts of the name, for
  /// example `ml_newspaper`.
  String get group => groupOf(name);

  /// The Tesseract language the name asks for, or null when the prefix is
  /// not one the tool knows.
  String? get language => languageOf(name);
}

/// Picture types the tool reads.
const Set<String> sampleImageExtensions = <String>{'.png', '.jpg', '.jpeg'};

/// Suffix of a correct-text file: `name.gt.txt`.
const String truthSuffix = '.gt.txt';

/// The report group for a sample [name].
String groupOf(String name) {
  final parts = name.split('_');
  return parts.length < 2 ? name : '${parts[0]}_${parts[1]}';
}

/// The Tesseract language code for a sample [name], from its first part.
String? languageOf(String name) {
  return switch (name.split('_').first) {
    'en' => 'eng',
    'ml' => 'mal',
    'mixed' => 'eng+mal',
    _ => null,
  };
}

/// Finds every picture in [folder] that has a matching correct-text file.
///
/// Pictures with no correct text are returned in [missingTruth] so the tool
/// can say so rather than skip them silently.
({List<Sample> samples, List<String> missingTruth}) findSamples(
  Directory folder,
) {
  final samples = <Sample>[];
  final missing = <String>[];

  final files = folder.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) continue;

    final extension = fileName.substring(dot).toLowerCase();
    if (!sampleImageExtensions.contains(extension)) continue;

    final name = fileName.substring(0, dot);
    final truth = File(
      '${folder.path}${Platform.pathSeparator}$name$truthSuffix',
    );

    if (truth.existsSync()) {
      samples.add(Sample(name: name, image: file, truth: truth));
    } else {
      missing.add(fileName);
    }
  }

  return (samples: samples, missingTruth: missing);
}
