import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';

/// The app data and settings that arrive at the end of a phone move.
///
/// Held in memory on the receiving phone until the user has seen the restore
/// preview and said yes. Nothing in it is written before that.
@immutable
class PhoneMoveData {
  /// Tags, albums, favourites, notes and places, in the backup format.
  final BackupPayload payload;

  /// The old phone's settings, or null when none came.
  final AppSettings? settings;

  const PhoneMoveData({required this.payload, this.settings});
}
