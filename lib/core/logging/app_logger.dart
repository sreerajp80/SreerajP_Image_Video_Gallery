import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_flavor_config.dart';

/// The six log levels from the engineering standard §14.1.
///
/// Each carries the numeric level `dart:developer` expects, so tools that
/// read the log (DevTools, the IDE console) sort and colour it correctly.
enum LogLevel {
  trace(300),
  debug(500),
  info(800),
  warning(900),
  error(1000),
  fatal(1200);

  const LogLevel(this.value);

  final int value;

  /// Levels that only make sense while building the app.
  bool get isVerbose => this == LogLevel.trace || this == LogLevel.debug;
}

/// Where a log line goes. Swapped out in tests.
typedef LogSink =
    void Function(
      LogLevel level,
      String message,
      Object? error,
      StackTrace? stackTrace,
    );

/// The app's one logger.
///
/// It writes through `dart:developer`, so it needs no package and no set-up
/// call, and nothing is written to a file on the device. `trace` and `debug`
/// are silent in the prod flavor.
///
/// Privacy rule (docs/security.md): log the name of the operation and the
/// kind of failure only. Never pass file paths, file names, GPS values, EXIF,
/// PINs, keys, pairing codes or any other media metadata in [message].
/// An `error` object is always reduced to its type name, in every flavor, so
/// an exception message that quotes a path cannot leak through either.
/// `CLAUDE.md` forbids logging private metadata "even in debug builds" (G48).
/// The stack trace is kept: it holds code locations, not user data.
abstract final class AppLogger {
  static const String _name = 'imgvidgal';

  static LogSink _sink = _developerSink;
  static bool Function() _verbose = _flavorIsDev;

  static bool _flavorIsDev() => AppFlavorConfig.current.isDev;

  static void _developerSink(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      message,
      name: _name,
      level: level.value,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final verbose = _verbose();
    if (level.isVerbose && !verbose) return;
    try {
      // An exception's text can carry a file path or a content URI, so only
      // its type is kept, in every flavor (G48).
      final safeError = error?.runtimeType.toString();
      _sink(level, message, safeError, stackTrace);
    } catch (_) {
      // Safe to ignore: the logger cannot log its own failure, and logging must
      // never break the app.
    }
  }

  static void trace(String message) => _write(LogLevel.trace, message);

  static void debug(String message) => _write(LogLevel.debug, message);

  static void info(String message) => _write(LogLevel.info, message);

  static void warning(String message, {Object? error}) =>
      _write(LogLevel.warning, message, error: error);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(LogLevel.error, message, error: error, stackTrace: stackTrace);

  static void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(LogLevel.fatal, message, error: error, stackTrace: stackTrace);

  /// Replaces the output and the verbose switch for a test.
  @visibleForTesting
  static void overrideForTest({LogSink? sink, bool? verbose}) {
    if (sink != null) _sink = sink;
    if (verbose != null) _verbose = () => verbose;
  }

  /// Puts back the real output after [overrideForTest].
  @visibleForTesting
  static void resetForTest() {
    _sink = _developerSink;
    _verbose = _flavorIsDev;
  }
}
