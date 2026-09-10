import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/privacy/forensic_metadata.dart';

/// Analyzes high-resolution media bytes for forensic lens, optical, and hardware metadata.
class ForensicInspectorService {
  const ForensicInspectorService();

  /// Inspects image [bytes] off the UI thread and builds [ForensicMetadata].
  Future<ForensicMetadata> inspectBytes(Uint8List bytes) async {
    if (bytes.length < 64) return const ForensicMetadata();

    try {
      if (bytes.length < 256 * 1024) {
        return inspectBytesSync(bytes);
      }
      return await Isolate.run(() => inspectBytesSync(bytes));
    } catch (_) {
      return const ForensicMetadata();
    }
  }

  /// Synchronous inspection of image bytes.
  ForensicMetadata inspectBytesSync(Uint8List bytes) {
    try {
      final exif = img.decodeJpgExif(bytes);
      if (exif == null || exif.isEmpty) {
        // Check if PNG or WebP has ICC profile
        final colorProf = _extractIccColorProfile(bytes);
        return ForensicMetadata(colorProfile: colorProf);
      }

      final image = exif.imageIfd;
      final subExif = exif.exifIfd;

      // Optical focal lengths
      final physicalFocal = _number(subExif[_tagFocalLength]);
      var focal35 = _number(subExif[_tagFocalLengthIn35mmFilm]);
      final fNumber = _number(subExif[_tagFNumber]);

      // Calculate crop factor
      double? cropFactor;
      if (focal35 != null &&
          physicalFocal != null &&
          physicalFocal > 0 &&
          focal35 > 0) {
        cropFactor = double.parse((focal35 / physicalFocal).toStringAsFixed(2));
      }

      // Sensor format classification
      final sensorFormat = _classifySensorFormat(cropFactor);

      // Hyperfocal distance calculation: H = (f^2) / (N * c)
      double? hyperfocalMeters;
      if (physicalFocal != null && fNumber != null && fNumber > 0) {
        final effectiveCrop = cropFactor ?? 1.0;
        final circleOfConfusionMm = 0.030 / effectiveCrop;
        final hMm =
            (physicalFocal * physicalFocal) / (fNumber * circleOfConfusionMm);
        hyperfocalMeters = double.parse((hMm / 1000.0).toStringAsFixed(2));
      }

      // Exposure bias (EV)
      final exposureBiasVal = _signedRational(subExif[_tagExposureBiasValue]);
      final exposureBiasStr = _formatExposureBias(exposureBiasVal);

      // Shutter actuation count
      final shutterActuations = _extractShutterActuations(subExif);

      // Color profile
      final colorProfile =
          _extractIccColorProfile(bytes) ??
          _colorSpaceName(_integer(subExif[_tagColorSpace]));

      // Hardware serials and specifications
      final bodySerial =
          _text(subExif[_tagBodySerialNumber]) ??
          _text(image[_tagCameraSerialNumber]);
      final lensModel = _text(subExif[_tagLensModel]);
      final lensMake = _text(subExif[_tagLensMake]);
      final lensSerial = _text(subExif[_tagLensSerialNumber]);
      final lensSpec = _formatLensSpecification(subExif[_tagLensSpecification]);

      // Program and metering
      final exposureProgram = _exposureProgram(
        _integer(subExif[_tagExposureProgram]),
      );
      final meteringMode = _meteringMode(_integer(subExif[_tagMeteringMode]));
      final sensingMethod = _sensingMethod(
        _integer(subExif[_tagSensingMethod]),
      );
      final sceneCaptureType = _sceneCaptureType(
        _integer(subExif[_tagSceneCaptureType]),
      );
      final digitalZoomRatio = _number(subExif[_tagDigitalZoomRatio]);
      final flashDetails = _flashDetails(_integer(subExif[_tagFlash]));

      return ForensicMetadata(
        cropFactor: cropFactor,
        sensorFormat: sensorFormat,
        focalLength35mm: focal35,
        physicalFocalLength: physicalFocal,
        hyperfocalDistanceMeters: hyperfocalMeters,
        shutterActuations: shutterActuations,
        exposureBias: exposureBiasVal,
        exposureBiasString: exposureBiasStr,
        colorProfile: colorProfile,
        bodySerialNumber: bodySerial,
        lensModel: lensModel,
        lensMake: lensMake,
        lensSerialNumber: lensSerial,
        lensSpecification: lensSpec,
        exposureProgram: exposureProgram,
        meteringMode: meteringMode,
        sensingMethod: sensingMethod,
        sceneCaptureType: sceneCaptureType,
        digitalZoomRatio: digitalZoomRatio,
        flashDetails: flashDetails,
      );
    } catch (_) {
      return const ForensicMetadata();
    }
  }

  /// Classifies common sensor form factors from the crop factor.
  String? _classifySensorFormat(double? cropFactor) {
    if (cropFactor == null) return null;
    if (cropFactor <= 1.05) return 'Full Frame (35mm)';
    if (cropFactor >= 1.4 && cropFactor <= 1.7) return 'APS-C (~1.5x)';
    if (cropFactor >= 1.9 && cropFactor <= 2.2)
      return 'Micro Four Thirds (2.0x)';
    if (cropFactor >= 2.5 && cropFactor <= 2.9) return '1-inch Type (2.7x)';
    if (cropFactor >= 3.0 && cropFactor <= 4.5) {
      return 'Mobile Sensor (~1/1.3" - 1/1.7")';
    }
    if (cropFactor > 4.5) return 'Mobile Compact Sensor (~1/2.5")';
    return '${cropFactor.toStringAsFixed(1)}x Crop';
  }

  /// Formats exposure bias as a clean EV string (e.g. "+0.7 EV", "-1.0 EV", "0 EV").
  String? _formatExposureBias(double? bias) {
    if (bias == null) return null;
    if (bias.abs() < 0.01) return '0 EV';
    final sign = bias > 0 ? '+' : '';
    return '$sign${bias.toStringAsFixed(1)} EV';
  }

  /// Extracts shutter actuation count from MakerNote or proprietary EXIF tags.
  int? _extractShutterActuations(img.IfdDirectory exif) {
    // Nikon Shutter Count tag
    final nikonVal = exif[_tagShutterCountNikon];
    if (nikonVal != null) {
      final count = nikonVal.toInt();
      if (count > 0) return count;
    }

    // Sony / Pentax shutter count tag
    final sonyVal = exif[_tagShutterCountSony];
    if (sonyVal != null) {
      final count = sonyVal.toInt();
      if (count > 0) return count;
    }

    return null;
  }

  /// Scans for embedded ICC profile segments (JPEG APP2 / PNG iCCP).
  String? _extractIccColorProfile(Uint8List bytes) {
    try {
      // Check for JPEG APP2 ICC profile: 0xFF 0xE2 ... "ICC_PROFILE"
      final marker = [0xFF, 0xE2];
      final iccSignature = 'ICC_PROFILE'.codeUnits;

      for (var i = 0; i < bytes.length - 30; i++) {
        if (bytes[i] == marker[0] && bytes[i + 1] == marker[1]) {
          var matched = true;
          for (var j = 0; j < iccSignature.length; j++) {
            if (bytes[i + 4 + j] != iccSignature[j]) {
              matched = false;
              break;
            }
          }
          if (matched) {
            // Search inside the ICC profile payload for description tag ('desc')
            final limit = mathMin(i + 1024, bytes.length - 4);
            for (var k = i + 18; k < limit; k++) {
              if (bytes[k] == 0x64 &&
                  bytes[k + 1] == 0x65 &&
                  bytes[k + 2] == 0x73 &&
                  bytes[k + 3] == 0x63) {
                // Found 'desc' tag, read description string length
                final textLength =
                    (bytes[k + 8] << 24) |
                    (bytes[k + 9] << 16) |
                    (bytes[k + 10] << 8) |
                    bytes[k + 11];
                if (textLength > 0 &&
                    textLength < 128 &&
                    k + 12 + textLength <= bytes.length) {
                  final name = String.fromCharCodes(
                    bytes.sublist(k + 12, k + 12 + textLength),
                  ).replaceAll(String.fromCharCode(0), '').trim();
                  if (name.isNotEmpty) return name;
                }
              }
            }
            return 'Embedded ICC Profile';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String? _colorSpaceName(int? value) {
    switch (value) {
      case 1:
        return 'sRGB';
      case 2:
        return 'Adobe RGB';
      case 0xFFFF:
        return 'Wide Color Gamut (Display P3)';
      default:
        return null;
    }
  }

  String? _exposureProgram(int? value) {
    switch (value) {
      case 1:
        return 'Manual';
      case 2:
        return 'Program AE (Auto)';
      case 3:
        return 'Aperture Priority (A/Av)';
      case 4:
        return 'Shutter Priority (S/Tv)';
      case 5:
        return 'Creative program (depth of field)';
      case 6:
        return 'Action program (high shutter)';
      case 7:
        return 'Portrait mode';
      case 8:
        return 'Landscape mode';
      default:
        return null;
    }
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
        return 'Multi-segment / Pattern';
      case 6:
        return 'Partial';
      default:
        return null;
    }
  }

  String? _sensingMethod(int? value) {
    switch (value) {
      case 1:
        return 'Not defined';
      case 2:
        return 'One-chip color area sensor';
      case 3:
        return 'Two-chip color area sensor';
      case 4:
        return 'Three-chip color area sensor';
      case 5:
        return 'Color sequential area sensor';
      case 7:
        return 'Trilinear sensor';
      case 8:
        return 'Color sequential linear sensor';
      default:
        return null;
    }
  }

  String? _sceneCaptureType(int? value) {
    switch (value) {
      case 0:
        return 'Standard';
      case 1:
        return 'Landscape';
      case 2:
        return 'Portrait';
      case 3:
        return 'Night scene';
      default:
        return null;
    }
  }

  String? _flashDetails(int? value) {
    if (value == null) return null;
    final fired = (value & 0x1) == 1;
    final returnStatus = (value >> 1) & 0x3;

    final buffer = StringBuffer(fired ? 'Flash fired' : 'No flash');
    if (fired) {
      if (returnStatus == 2) buffer.write(' (strobe return not detected)');
      if (returnStatus == 3) buffer.write(' (strobe return detected)');
    }
    return buffer.toString();
  }

  String? _formatLensSpecification(img.IfdValue? value) {
    if (value == null || value.length < 4) return null;
    try {
      final minFocal = value.toDouble(0);
      final maxFocal = value.toDouble(1);
      final minAperture = value.toDouble(2);
      final maxAperture = value.toDouble(3);

      final focalStr = minFocal == maxFocal
          ? '${minFocal.toStringAsFixed(0)}mm'
          : '${minFocal.toStringAsFixed(0)}-${maxFocal.toStringAsFixed(0)}mm';

      final apertureStr = minAperture == maxAperture
          ? 'f/${minAperture.toStringAsFixed(1)}'
          : 'f/${minAperture.toStringAsFixed(1)}-${maxAperture.toStringAsFixed(1)}';

      return '$focalStr $apertureStr';
    } catch (_) {
      return null;
    }
  }

  String? _text(img.IfdValue? value) {
    if (value == null) return null;
    final text = value.toString().replaceAll(String.fromCharCode(0), '').trim();
    return text.isEmpty ? null : text;
  }

  double? _number(img.IfdValue? value) {
    if (value == null) return null;
    double number;
    if (value is img.IfdValueShort || value is img.IfdValueLong) {
      number = value.toInt().toDouble();
    } else {
      number = value.toDouble();
      if (number == 0.0 && value.toInt() != 0) {
        number = value.toInt().toDouble();
      }
    }
    if (number.isNaN || number.isInfinite) return null;
    return number;
  }

  int? _integer(img.IfdValue? value) {
    if (value == null) return null;
    return value.toInt();
  }

  double? _signedRational(img.IfdValue? value) {
    if (value == null) return null;
    if (value is img.IfdValueRational && value.value.isNotEmpty) {
      final r = value.value[0];
      var num = r.numerator;
      var den = r.denominator;
      if (num > 0x7FFFFFFF) num = num - 0x100000000;
      if (den > 0x7FFFFFFF) den = den - 0x100000000;
      if (den == 0) return null;
      return num / den;
    }
    final num = value.toDouble();
    if (num.isNaN || num.isInfinite) return null;
    return num;
  }

  int mathMin(int a, int b) => a < b ? a : b;

  // EXIF 2.3 Tag numbers
  static const int _tagFocalLength = 0x920A;
  static const int _tagFocalLengthIn35mmFilm = 0xA405;
  static const int _tagFNumber = 0x829D;
  static const int _tagExposureBiasValue = 0x9204;
  static const int _tagExposureProgram = 0x8822;
  static const int _tagMeteringMode = 0x9207;
  static const int _tagColorSpace = 0xA001;
  static const int _tagFlash = 0x9209;
  static const int _tagBodySerialNumber = 0xA431;
  static const int _tagLensModel = 0xA434;
  static const int _tagLensMake = 0xA433;
  static const int _tagLensSerialNumber = 0xA435;
  static const int _tagLensSpecification = 0xA432;
  static const int _tagSensingMethod = 0xA417;
  static const int _tagSceneCaptureType = 0xA406;
  static const int _tagDigitalZoomRatio = 0xA404;
  static const int _tagCameraSerialNumber = 0xC62F;

  // MakerNote shutter tags
  static const int _tagShutterCountNikon = 0x00A7;
  static const int _tagShutterCountSony = 0x0038;
}
