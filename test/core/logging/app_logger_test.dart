import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

class _Line {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  _Line(this.level, this.message, this.error, this.stackTrace);
}

void main() {
  late List<_Line> lines;

  void capture({required bool verbose}) {
    lines = <_Line>[];
    AppLogger.overrideForTest(
      verbose: verbose,
      sink: (level, message, error, stackTrace) =>
          lines.add(_Line(level, message, error, stackTrace)),
    );
  }

  tearDown(AppLogger.resetForTest);

  test('every level reaches the sink in the dev flavor', () {
    capture(verbose: true);

    AppLogger.trace('t');
    AppLogger.debug('d');
    AppLogger.info('i');
    AppLogger.warning('w');
    AppLogger.error('e');
    AppLogger.fatal('f');

    expect(lines.map((l) => l.level), LogLevel.values);
  });

  test('trace and debug are silent in the prod flavor', () {
    capture(verbose: false);

    AppLogger.trace('t');
    AppLogger.debug('d');
    AppLogger.info('i');

    expect(lines.map((l) => l.level), <LogLevel>[LogLevel.info]);
  });

  test('even in the dev flavor an error is reduced to its type (G48)', () {
    capture(verbose: true);
    const error = FormatException('/storage/emulated/0/DCIM/secret.jpg');
    final stack = StackTrace.current;

    AppLogger.error('op failed', error: error, stackTrace: stack);

    expect(lines.single.error, 'FormatException');
    expect(lines.single.error.toString(), isNot(contains('DCIM')));
    expect(lines.single.stackTrace, same(stack));
  });

  test('outside the dev flavor an error is reduced to its type', () {
    capture(verbose: false);

    AppLogger.error(
      'op failed',
      error: const FormatException('/storage/emulated/0/DCIM/secret.jpg'),
      stackTrace: StackTrace.current,
    );

    expect(lines.single.error, 'FormatException');
    expect(lines.single.error.toString(), isNot(contains('DCIM')));
    expect(lines.single.stackTrace, isNotNull);
  });

  test('a failing sink never throws out of the logger', () {
    AppLogger.overrideForTest(
      verbose: true,
      sink: (_, _, _, _) => throw StateError('sink broke'),
    );

    expect(() => AppLogger.error('x'), returnsNormally);
  });
}
