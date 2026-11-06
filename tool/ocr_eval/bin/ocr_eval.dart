// Measures OCR accuracy on a fixed set of test pictures.
// Developer tool only; it is not part of the app. See tool/ocr_eval/README.md.
//
// Run from the project root:  dart run tool/ocr_eval/bin/ocr_eval.dart --help

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../src/error_rate.dart';
import '../src/sample.dart';
import '../src/text_normaliser.dart';

const String _usage = '''
Measures OCR accuracy on the pictures in tool/ocr_eval/samples/.

Usage: dart run tool/ocr_eval/bin/ocr_eval.dart [options]

  --samples <folder>    Test pictures and .gt.txt files   (default: tool/ocr_eval/samples)
  --tessdata <folder>   Folder with the .traineddata files (default: assets/tessdata)
  --tesseract <path>    Tesseract program                  (default: \$TESSERACT or "tesseract")
  --lang <code>         Force one language for every sample, e.g. eng, mal, eng+mal.
                        Without it, the name prefix decides: en_ -> eng, ml_ -> mal,
                        mixed_ -> eng+mal.
  --psm <n>             Tesseract page segmentation mode   (default: 3, as the app today)
  --dpi <n>             Tell Tesseract the picture's DPI   (default: not set, as the app today)
  --label <text>        Name for the results file          (default: run)
  --help                Show this text
''';

/// Longest one picture may take, the same limit the app uses.
const Duration _timeout = Duration(seconds: 120);

Future<void> main(List<String> arguments) async {
  final options = _parse(arguments);
  if (options == null) {
    print(_usage);
    exit(64);
  }
  if (options.containsKey('help')) {
    print(_usage);
    return;
  }

  final samplesDir = Directory(options['samples'] ?? 'tool/ocr_eval/samples');
  final tessdata = options['tessdata'] ?? 'assets/tessdata';
  final tesseract =
      options['tesseract'] ?? Platform.environment['TESSERACT'] ?? 'tesseract';
  final forcedLanguage = options['lang'];
  final psm = options['psm'] ?? '3';
  final dpi = options['dpi'];
  final label = _safeLabel(options['label'] ?? 'run');

  if (!samplesDir.existsSync()) {
    stderr.writeln('ERROR: samples folder not found: ${samplesDir.path}');
    exit(66);
  }
  if (!Directory(tessdata).existsSync()) {
    stderr.writeln('ERROR: tessdata folder not found: $tessdata');
    exit(66);
  }

  final version = await _tesseractVersion(tesseract);
  if (version == null) {
    stderr.writeln(
      'ERROR: could not run Tesseract ("$tesseract").\n'
      'Install it (see tool/ocr_eval/README.md), then put it on PATH, set\n'
      'the TESSERACT environment variable, or pass --tesseract <path>.',
    );
    exit(69);
  }

  final found = findSamples(samplesDir);
  for (final name in found.missingTruth) {
    stderr.writeln('WARNING: no $truthSuffix for $name; skipped.');
  }
  if (found.samples.isEmpty) {
    stderr.writeln('ERROR: no samples with correct text in ${samplesDir.path}');
    exit(66);
  }

  const normaliser = TextNormaliser();
  final scores = <_Score>[];

  for (final sample in found.samples) {
    final language = forcedLanguage ?? sample.language;
    if (language == null) {
      stderr.writeln(
        'WARNING: ${sample.name}: name must start with en_, ml_ or mixed_ '
        '(or pass --lang); skipped.',
      );
      continue;
    }

    stdout.write('Reading ${sample.name} ($language) ... ');
    final raw = await _readText(
      tesseract,
      sample.image.path,
      tessdata: tessdata,
      language: language,
      psm: psm,
      dpi: dpi,
    );
    if (raw == null) {
      print('FAILED');
      scores.add(_Score.failed(sample));
      continue;
    }

    final rate = measureErrorRate(
      truth: normaliser.normalise(sample.truth.readAsStringSync()),
      result: normaliser.normalise(raw),
    );
    print('CER ${_percent(rate.cer)}  WER ${_percent(rate.wer)}');
    scores.add(_Score(sample, rate));
  }

  final report = _report(
    scores,
    tesseractVersion: version,
    tessdata: tessdata,
    psm: psm,
    dpi: dpi,
    forcedLanguage: forcedLanguage,
    label: label,
  );

  print('');
  print(report);

  final resultsDir = Directory('tool/ocr_eval/results')
    ..createSync(recursive: true);
  final file = File('${resultsDir.path}/${_timestamp()}_$label.md');
  file.writeAsStringSync(report);
  print('Saved: ${file.path}');
}

class _Score {
  final Sample sample;
  final ErrorRate? rate;

  const _Score(this.sample, ErrorRate this.rate);

  const _Score.failed(this.sample) : rate = null;
}

/// Reads `--name value` pairs. Returns null on anything it does not know.
Map<String, String>? _parse(List<String> arguments) {
  const known = <String>{
    'samples',
    'tessdata',
    'tesseract',
    'lang',
    'psm',
    'dpi',
    'label',
  };
  final options = <String, String>{};

  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument == '--help' || argument == '-h') {
      options['help'] = '';
      continue;
    }
    if (!argument.startsWith('--')) return null;

    final name = argument.substring(2);
    if (!known.contains(name) || i + 1 >= arguments.length) return null;
    options[name] = arguments[++i];
  }

  return options;
}

Future<String?> _tesseractVersion(String tesseract) async {
  try {
    final result = await Process.run(tesseract, const <String>['--version']);
    if (result.exitCode != 0) return null;
    // Older builds print the version on stderr, newer ones on stdout.
    final text = '${result.stdout}\n${result.stderr}';
    final match = RegExp(r'tesseract\s+v?(\S+)').firstMatch(text);
    return match?.group(1) ?? 'unknown';
  } catch (_) {
    return null;
  }
}

/// Runs Tesseract with the same settings the app passes to the plugin.
Future<String?> _readText(
  String tesseract,
  String imagePath, {
  required String tessdata,
  required String language,
  required String psm,
  String? dpi,
}) async {
  final arguments = <String>[
    imagePath,
    'stdout',
    '--tessdata-dir',
    tessdata,
    '-l',
    language,
    '--psm',
    psm,
    if (dpi != null) ...<String>['--dpi', dpi],
    // The app sets this too (lib/services/ocr/ocr_engine.dart).
    '-c',
    'preserve_interword_spaces=1',
  ];

  try {
    final process = await Process.start(tesseract, arguments);
    final output = process.stdout.transform(utf8.decoder).join();
    // Drained so a chatty run cannot fill the pipe and stall.
    final errors = process.stderr.drain<void>();

    final exitCode = await process.exitCode.timeout(
      _timeout,
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
    await errors;
    if (exitCode != 0) return null;
    return await output;
  } catch (_) {
    return null;
  }
}

String _report(
  List<_Score> scores, {
  required String tesseractVersion,
  required String tessdata,
  required String psm,
  required String? dpi,
  required String? forcedLanguage,
  required String label,
}) {
  final buffer = StringBuffer()
    ..writeln('# OCR accuracy: $label')
    ..writeln()
    ..writeln('- Date: ${DateTime.now().toIso8601String().substring(0, 19)}')
    ..writeln('- Tesseract: $tesseractVersion')
    ..writeln('- Language data: `$tessdata`')
    ..writeln('- Language: ${forcedLanguage ?? 'from sample name'}')
    ..writeln('- psm: $psm, dpi: ${dpi ?? 'not set'}')
    ..writeln()
    ..writeln(
      'CER and WER are mean values per sample. Lower is better; 0% is '
      'perfect.',
    )
    ..writeln()
    ..writeln(
      '| Group | Samples | Failed | Mean CER | Mean WER | Worst (CER) |',
    )
    ..writeln('|---|---|---|---|---|---|');

  final groups = <String, List<_Score>>{};
  for (final score in scores) {
    groups.putIfAbsent(score.sample.group, () => <_Score>[]).add(score);
  }

  for (final entry in groups.entries) {
    buffer.writeln(_row(entry.key, entry.value));
  }
  buffer.writeln(_row('**All**', scores));

  return buffer.toString();
}

String _row(String group, List<_Score> scores) {
  final measured = scores.where((s) => s.rate != null).toList()
    ..sort((a, b) => b.rate!.cer.compareTo(a.rate!.cer));
  final failed = scores.length - measured.length;

  if (measured.isEmpty) {
    return '| $group | ${scores.length} | $failed | - | - | - |';
  }

  double mean(double Function(ErrorRate r) pick) =>
      measured.map((s) => pick(s.rate!)).reduce((a, b) => a + b) /
      measured.length;

  final worst = measured
      .take(3)
      .map((s) => '${s.sample.name} ${_percent(s.rate!.cer)}')
      .join(', ');

  return '| $group | ${scores.length} | $failed | '
      '${_percent(mean((r) => r.cer))} | ${_percent(mean((r) => r.wer))} | '
      '$worst |';
}

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _safeLabel(String label) {
  final safe = label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  return safe.isEmpty ? 'run' : safe;
}

String _timestamp() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}
