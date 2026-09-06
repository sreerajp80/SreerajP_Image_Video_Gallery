import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:path/path.dart' as p;

/// Keeps the user's preferences in one small JSON file.
///
/// The same shape as the recent-searches store: one file, written through
/// [AtomicSaver] so a crash mid-write cannot leave half a file behind, and
/// nothing here ever throws at the caller. A missing, unreadable, or corrupt
/// file simply means "defaults", and a failed write is dropped.
///
/// That is deliberate. Preferences are a convenience. Failing a launch, or
/// throwing a dialog at somebody, because a settings file went bad would be a
/// worse outcome than quietly starting from the defaults.
///
/// This is not secure storage on purpose. Theme, language, grid density and
/// two switches are not secrets. The vault keeps its own settings in
/// `flutter_secure_storage`, and that stays where it is.
class AppSettingsService {
  /// Folder the settings file is kept in.
  final Directory directory;

  const AppSettingsService({required this.directory});

  /// Full path of the settings file.
  String get filePath =>
      p.join(directory.path, AppConstants.appSettingsFileName);

  /// Reads the stored preferences, or the defaults if there are none.
  Future<AppSettings> load() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return AppSettings.defaults;

      return AppSettings.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      // Missing, truncated, or hand-edited into nonsense. Start clean.
      return AppSettings.defaults;
    }
  }

  /// Writes [settings] to disk.
  ///
  /// Returns whether the write landed. Callers may ignore it: the in-memory
  /// state is already correct either way, and only the next launch would
  /// notice that a save was lost.
  Future<bool> save(AppSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      await AtomicSaver.writeBytes(
        filePath,
        Uint8List.fromList(utf8.encode(json)),
      );
      return true;
    } catch (_) {
      // A full disk must not stop somebody changing their theme.
      return false;
    }
  }
}
