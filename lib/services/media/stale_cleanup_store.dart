import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers when the ghost-entry cleanup last ran.
///
/// An interface so the scanner can be tested without real preferences.
abstract class StaleCleanupStore {
  /// When the cleanup last ran, or null when it never has.
  Future<DateTime?> lastRun();

  /// Records that the cleanup ran at [time].
  Future<void> setLastRun(DateTime time);
}

/// Keeps the time in `SharedPreferences`. It is only a time, not a secret.
class SharedPreferencesStaleCleanupStore implements StaleCleanupStore {
  const SharedPreferencesStaleCleanupStore();

  @override
  Future<DateTime?> lastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(AppConstants.staleCleanupLastRunKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> setLastRun(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.staleCleanupLastRunKey,
      time.millisecondsSinceEpoch,
    );
  }
}

/// Keeps the time in memory. For tests.
class MemoryStaleCleanupStore implements StaleCleanupStore {
  DateTime? value;

  MemoryStaleCleanupStore([this.value]);

  @override
  Future<DateTime?> lastRun() async => value;

  @override
  Future<void> setLastRun(DateTime time) async => value = time;
}
