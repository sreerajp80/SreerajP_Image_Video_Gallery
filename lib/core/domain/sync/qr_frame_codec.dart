import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// The one-time key the receiving phone shows as its first QR code.
class QrSyncKey {
  /// Ties the data frames to this key, so frames from another sync are
  /// ignored. Eight lower-case hex characters.
  final String sessionId;

  /// The AES key the data is encrypted with. 32 bytes.
  final Uint8List key;

  const QrSyncKey({required this.sessionId, required this.key});
}

/// Turns app data into a loop of QR codes, and back.
///
/// Pure Dart, so every rule can be tested without a camera.
///
/// ### Formats
///
/// The key code: `DRISHYA-QK1|<session>|<key>`.
///
/// Each data frame: `DRISHYA-QD1|<session>|<index>|<count>|<check>|<data>`.
///
/// `<data>` is base64url without padding. `<check>` is the first 8 hex
/// characters of a SHA-256 over the other parts, so a misread frame is
/// dropped at once. Whether the data as a whole is genuine is decided later,
/// when it is decrypted: AES-GCM refuses anything changed or incomplete.
class QrFrameCodec {
  const QrFrameCodec._();

  static const String _sep = '|';

  // ------------------------------------------------------------------- key

  static String encodeKey(QrSyncKey key) => <String>[
    AppConstants.qrSyncKeyPrefix,
    key.sessionId,
    _b64(key.key),
  ].join(_sep);

  /// Reads a key code, or null when it is not one of ours.
  static QrSyncKey? decodeKey(String raw) {
    final parts = raw.trim().split(_sep);
    if (parts.length != 3 || parts[0] != AppConstants.qrSyncKeyPrefix) {
      return null;
    }
    if (!_isSessionId(parts[1])) return null;
    final key = _unb64(parts[2]);
    if (key == null || key.length != AppConstants.syncSessionKeyBytes) {
      return null;
    }
    return QrSyncKey(sessionId: parts[1], key: key);
  }

  // ---------------------------------------------------------------- frames

  /// How many frames [byteCount] bytes of data need.
  static int frameCountFor(int byteCount) {
    const size = AppConstants.qrSyncFrameDataBytes;
    return byteCount <= 0 ? 0 : (byteCount + size - 1) ~/ size;
  }

  /// Splits [data] into frames for the session [sessionId].
  static List<String> split(Uint8List data, String sessionId) {
    const size = AppConstants.qrSyncFrameDataBytes;
    final count = frameCountFor(data.length);
    return <String>[
      for (var i = 0; i < count; i++)
        _frame(
          sessionId,
          i,
          count,
          _b64(
            Uint8List.sublistView(
              data,
              i * size,
              (i + 1) * size > data.length ? data.length : (i + 1) * size,
            ),
          ),
        ),
    ];
  }

  static String _frame(String session, int index, int count, String data) {
    final check = _check(session, index, count, data);
    return <String>[
      AppConstants.qrSyncFramePrefix,
      session,
      '$index',
      '$count',
      check,
      data,
    ].join(_sep);
  }

  static String _check(String session, int index, int count, String data) {
    final digest = sha256.convert(utf8.encode('$session|$index|$count|$data'));
    return digest.toString().substring(0, 8);
  }

  static bool _isSessionId(String value) =>
      RegExp(r'^[0-9a-f]{8}$').hasMatch(value);

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List? _unb64(String value) {
    if (value.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return null;
    }
    try {
      return base64Url.decode(value.padRight((value.length + 3) & ~3, '='));
    } catch (_) {
      // Safe to ignore: bad base64 reads as no data, and the frame is dropped.
      return null;
    }
  }
}

/// Collects data frames as the camera reads them, in any order.
///
/// Frames for another session, misread frames, and repeats are ignored. A
/// sender that claims more frames than [AppConstants.qrSyncMaxFrames] is
/// refused, so a stranger's code cannot make this phone wait for ever.
class QrFrameCollector {
  final String sessionId;

  final Map<int, Uint8List> _parts = <int, Uint8List>{};
  int _count = 0;

  QrFrameCollector({required this.sessionId});

  /// How many frames the sender will play, or 0 before the first frame.
  int get total => _count;

  /// How many distinct frames have been read.
  int get received => _parts.length;

  bool get isComplete => _count > 0 && _parts.length == _count;

  /// Takes one scanned code. Returns true when it was a new, good frame.
  bool add(String raw) {
    final parts = raw.trim().split(QrFrameCodec._sep);
    if (parts.length != 6 || parts[0] != AppConstants.qrSyncFramePrefix) {
      return false;
    }
    if (parts[1] != sessionId) return false;

    final index = int.tryParse(parts[2]);
    final count = int.tryParse(parts[3]);
    if (index == null || count == null) return false;
    if (count <= 0 || count > AppConstants.qrSyncMaxFrames) return false;
    if (index < 0 || index >= count) return false;
    if (_count != 0 && count != _count) return false;

    if (QrFrameCodec._check(parts[1], index, count, parts[5]) != parts[4]) {
      return false;
    }
    if (_parts.containsKey(index)) return false;

    final data = QrFrameCodec._unb64(parts[5]);
    if (data == null ||
        data.isEmpty ||
        data.length > AppConstants.qrSyncFrameDataBytes) {
      return false;
    }

    _count = count;
    _parts[index] = data;
    return true;
  }

  /// The data, joined in order, or null while frames are missing.
  Uint8List? assemble() {
    if (!isComplete) return null;
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < _count; i++) {
      out.add(_parts[i]!);
    }
    return out.takeBytes();
  }
}
