import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';

/// Reads camera metadata out of image bytes.
///
/// It uses `decodeJpgExif` from the `image` package, which walks only the JPEG
/// headers and never decodes pixels, so reading metadata from a large photo
/// stays cheap. Formats that carry no readable EXIF (PNG, WEBP, most RAW,
/// video) simply return null.
///
/// Nothing here throws. A truncated, corrupt, or plain wrong file returns null
/// and the details drawer falls back to the facts MediaStore already gave us.
class ExifReaderService {
  const ExifReaderService();

  /// Parses [bytes] on a background isolate.
  ///
  /// Header parsing is fast, but a big byte list still costs work, so it is
  /// kept off the UI thread. The isolate is skipped for small inputs where
  /// spawning would cost more than the parse itself.
  Future<ExifData?> read(Uint8List bytes) async {
    if (bytes.length > AppConstants.exifReadMaxBytes) return null;
    if (bytes.length < 64) return null;

    try {
      if (bytes.length < 256 * 1024) return parseBytes(bytes);
      return await Isolate.run(() => parseBytes(bytes));
    } catch (_) {
      return null;
    }
  }

  /// Parses [bytes] on the calling thread.
  ///
  /// Pure and synchronous, which is what makes the mapping unit testable.
  ExifData? parseBytes(Uint8List bytes) {
    try {
      final raw = img.decodeJpgExif(bytes);
      if (raw == null || raw.isEmpty) return null;
      return _map(raw);
    } catch (_) {
      return null;
    }
  }

  /// Turns the `image` package structure into our own immutable model.
  ExifData? _map(img.ExifData raw) {
    final image = raw.imageIfd;
    final exif = raw.exifIfd;
    final gps = raw.gpsIfd;

    final data = ExifData(
      make: _text(image[_tagMake]),
      model: _text(image[_tagModel]),
      lensModel: _text(exif[_tagLensModel]),
      focalLength: _number(exif[_tagFocalLength]),
      fNumber: _number(exif[_tagFNumber]),
      iso: _integer(exif[_tagIso]),
      exposureTime: _exposureTime(exif[_tagExposureTime]),
      flash: _flash(_integer(exif[_tagFlash])),
      whiteBalance: _whiteBalance(_integer(exif[_tagWhiteBalance])),
      meteringMode: _meteringMode(_integer(exif[_tagMeteringMode])),
      latitude: _coordinate(
        gps[_tagGpsLatitude],
        _text(gps[_tagGpsLatitudeRef]),
      ),
      longitude: _coordinate(
        gps[_tagGpsLongitude],
        _text(gps[_tagGpsLongitudeRef]),
      ),
      altitude: _number(gps[_tagGpsAltitude]),
      dateTimeOriginal: _exifDate(_text(exif[_tagDateTimeOriginal])),
      software: _text(image[_tagSoftware]),
      colorSpace: _colorSpace(_integer(exif[_tagColorSpace])),
    );

    return _isEmpty(data) ? null : data;
  }

  /// Whether nothing useful was found, so the caller can show MediaStore facts.
  bool _isEmpty(ExifData data) {
    return data.make == null &&
        data.model == null &&
        data.lensModel == null &&
        data.focalLength == null &&
        data.fNumber == null &&
        data.iso == null &&
        data.exposureTime == null &&
        data.flash == null &&
        data.whiteBalance == null &&
        data.meteringMode == null &&
        data.latitude == null &&
        data.longitude == null &&
        data.altitude == null &&
        data.dateTimeOriginal == null &&
        data.software == null &&
        data.colorSpace == null;
  }

  String? _text(img.IfdValue? value) {
    if (value == null) return null;
    // EXIF strings are padded with a null character, stripped here too.
    final text = value.toString().replaceAll(_nullChar, '').trim();
    return text.isEmpty ? null : text;
  }

  double? _number(img.IfdValue? value) {
    if (value == null) return null;
    final number = value.toDouble();
    if (number.isNaN || number.isInfinite) return null;
    return number;
  }

  int? _integer(img.IfdValue? value) {
    if (value == null) return null;
    return value.toInt();
  }

  /// Formats shutter speed the way a camera app shows it.
  ///
  /// Fast shutters read better as a fraction (`1/250s`), slow ones as seconds.
  String? _exposureTime(img.IfdValue? value) {
    final seconds = _number(value);
    if (seconds == null || seconds <= 0) return null;
    if (seconds >= 1) return '${_trim(seconds)}s';
    return '1/${(1 / seconds).round()}s';
  }

  /// Reads a GPS coordinate as decimal degrees.
  ///
  /// Cameras normally store degrees, minutes, and seconds as three values, but
  /// some writers store a single decimal number instead. Both are accepted.
  /// [ref] is the hemisphere letter; S and W mean a negative coordinate.
  double? _coordinate(img.IfdValue? value, String? ref) {
    if (value == null || value.length < 1) return null;

    double decimal;
    if (value.length >= 3) {
      final degrees = value.toDouble(0);
      final minutes = value.toDouble(1);
      final seconds = value.toDouble(2);
      if (degrees.isNaN || minutes.isNaN || seconds.isNaN) return null;
      decimal = degrees + minutes / 60 + seconds / 3600;
    } else {
      decimal = value.toDouble();
    }
    if (decimal.isNaN || decimal.isInfinite) return null;

    final hemisphere = ref?.toUpperCase();
    final isNegative = hemisphere == 'S' || hemisphere == 'W';
    return isNegative ? -decimal.abs() : decimal;
  }

  /// Parses the EXIF date format, which is `yyyy:MM:dd HH:mm:ss`.
  DateTime? _exifDate(String? raw) {
    if (raw == null || raw.length < 19) return null;
    final normalized =
        '${raw.substring(0, 4)}-${raw.substring(5, 7)}-${raw.substring(8, 10)}'
        'T${raw.substring(11, 19)}';
    return DateTime.tryParse(normalized);
  }

  /// The flash tag is a bit field; bit 0 says whether the flash actually fired.
  String? _flash(int? value) {
    if (value == null) return null;
    return (value & 0x1) == 1 ? 'Flash fired' : 'No flash';
  }

  String? _whiteBalance(int? value) {
    if (value == null) return null;
    return value == 0 ? 'Auto' : 'Manual';
  }

  String? _meteringMode(int? value) {
    switch (value) {
      case 1:
        return 'Average';
      case 2:
        return 'Center-weighted average';
      case 3:
        return 'Spot';
      case 4:
        return 'Multi-spot';
      case 5:
        return 'Pattern';
      case 6:
        return 'Partial';
      default:
        return null;
    }
  }

  String? _colorSpace(int? value) {
    switch (value) {
      case 1:
        return 'sRGB';
      case 0xFFFF:
        return 'Uncalibrated';
      default:
        return null;
    }
  }

  /// Drops a trailing `.0` so `2.0s` reads as `2s`.
  String _trim(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  /// The character EXIF pads its strings with.
  static final String _nullChar = String.fromCharCode(0);

  // EXIF tag numbers, from the EXIF 2.3 specification.
  static const int _tagMake = 0x010F;
  static const int _tagModel = 0x0110;
  static const int _tagSoftware = 0x0131;
  static const int _tagExposureTime = 0x829A;
  static const int _tagFNumber = 0x829D;
  static const int _tagIso = 0x8827;
  static const int _tagDateTimeOriginal = 0x9003;
  static const int _tagMeteringMode = 0x9207;
  static const int _tagFlash = 0x9209;
  static const int _tagFocalLength = 0x920A;
  static const int _tagColorSpace = 0xA001;
  static const int _tagWhiteBalance = 0xA403;
  static const int _tagLensModel = 0xA434;
  static const int _tagGpsLatitudeRef = 0x0001;
  static const int _tagGpsLatitude = 0x0002;
  static const int _tagGpsLongitudeRef = 0x0003;
  static const int _tagGpsLongitude = 0x0004;
  static const int _tagGpsAltitude = 0x0006;
}
