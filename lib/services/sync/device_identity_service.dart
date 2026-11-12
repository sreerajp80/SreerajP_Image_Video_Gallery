import 'dart:math';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where this install's random id is kept.
///
/// An interface so tests can use a map instead of real preferences.
abstract class InstallIdStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// The real store, over `SharedPreferences`.
///
/// Plain preferences, not secure storage: the id is not a secret. It only
/// tells this phone's sends to another phone apart from its sends to a third.
class SharedPreferencesInstallIdStore implements InstallIdStore {
  final SharedPreferencesAsync _prefs;

  SharedPreferencesInstallIdStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(AppConstants.syncInstallIdPrefKey);

  @override
  Future<void> write(String value) =>
      _prefs.setString(AppConstants.syncInstallIdPrefKey, value);
}

/// Gives this install a random, stable id for Device Sync.
///
/// Made once, on first use, from a secure random source. Never a hardware id
/// (serial, IMEI, Android id), so it cannot be used to recognise the phone
/// outside this app, and it changes if the app is reinstalled.
class DeviceIdentityService {
  final InstallIdStore _store;
  final Random _random;

  String? _cached;

  DeviceIdentityService({InstallIdStore? store, Random? random})
    : _store = store ?? SharedPreferencesInstallIdStore(),
      _random = random ?? Random.secure();

  /// This install's id: 32 lower-case hex characters.
  Future<String> installId() async {
    final cached = _cached;
    if (cached != null) return cached;

    final stored = await _store.read();
    if (stored != null && _looksValid(stored)) {
      _cached = stored;
      return stored;
    }

    final fresh = List<String>.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _store.write(fresh);
    _cached = fresh;
    return fresh;
  }

  static bool _looksValid(String value) =>
      RegExp(r'^[0-9a-f]{32}$').hasMatch(value);
}
