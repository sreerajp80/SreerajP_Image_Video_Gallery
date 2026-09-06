import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Builds small PDF files by hand for the extractor tests.
///
/// Hand-built rather than checked in as binary fixtures: the awkward cases are
/// things like a wrong `/Length` or a `/Filter` given as an array, and writing
/// them out in code is the only way to say plainly which byte is the point of
/// each test.
class PdfTestFiles {
  const PdfTestFiles._();

  /// A PDF holding one image object, built from the pieces given.
  ///
  /// [dictionary] is the image object's dictionary, without the surrounding
  /// `<<` and `>>`, and without `/Length`, which is added to match [stream].
  static Uint8List withImage({
    required String dictionary,
    required List<int> stream,
    int objectNumber = 4,
    int? declaredLength,
    bool encrypted = false,
  }) {
    final body = BytesBuilder();

    void writeAscii(String text) => body.add(latin1.encode(text));

    writeAscii('%PDF-1.7\n');
    writeAscii('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    writeAscii('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
    writeAscii(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>\n'
      'endobj\n',
    );

    final length = declaredLength ?? stream.length;
    writeAscii(
      '$objectNumber 0 obj\n<< $dictionary /Length $length >>\nstream\n',
    );
    body.add(stream);
    writeAscii('\nendstream\nendobj\n');

    if (encrypted) {
      writeAscii('9 0 obj\n<< /Filter /Standard /V 2 /R 3 >>\nendobj\n');
      writeAscii('trailer\n<< /Root 1 0 R /Encrypt 9 0 R >>\n');
    } else {
      writeAscii('trailer\n<< /Root 1 0 R /Size 5 >>\n');
    }

    writeAscii('%%EOF\n');
    return body.toBytes();
  }

  /// A PDF whose `/Length` is an indirect reference, as many writers emit.
  static Uint8List withIndirectLength({
    required String dictionary,
    required List<int> stream,
  }) {
    final body = BytesBuilder();
    void writeAscii(String text) => body.add(latin1.encode(text));

    writeAscii('%PDF-1.4\n');
    writeAscii('1 0 obj\n<< /Type /Catalog >>\nendobj\n');
    writeAscii('4 0 obj\n<< $dictionary /Length 7 0 R >>\nstream\n');
    body.add(stream);
    writeAscii('\nendstream\nendobj\n');
    writeAscii('7 0 obj\n${stream.length}\nendobj\n');
    writeAscii('trailer\n<< /Root 1 0 R >>\n%%EOF\n');

    return body.toBytes();
  }

  /// The smallest thing that decodes as a JPEG, for the copy-straight-out path.
  ///
  /// A real 1x1 grey JPEG. The extractor never decodes it — it copies the
  /// bytes — but the test asserts the bytes come back whole, so they have to
  /// be a genuine file.
  static Uint8List tinyJpeg() {
    return Uint8List.fromList(<int>[
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, //
      0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
      0xFF, 0xDB, 0x00, 0x43, 0x00,
      ...List<int>.filled(64, 0x10),
      0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01,
      0x01, 0x11, 0x00,
      0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
      ...List<int>.filled(15, 0x00),
      0x00,
      0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01,
      ...List<int>.filled(15, 0x00),
      0x00,
      0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
      0x37, 0xFF, 0xD9,
    ]);
  }

  /// Raw RGB pixels, zipped the way `FlateDecode` expects.
  static Uint8List flateRgb(int width, int height) {
    final pixels = Uint8List(width * height * 3);
    for (var index = 0; index < pixels.length; index += 3) {
      pixels[index] = 200; // A colour that is obviously not black.
      pixels[index + 1] = 100;
      pixels[index + 2] = 50;
    }
    return Uint8List.fromList(ZLibEncoder().convert(pixels));
  }

  /// Raw grey pixels, zipped.
  static Uint8List flateGray(int width, int height) {
    final pixels = Uint8List(width * height);
    for (var index = 0; index < pixels.length; index++) {
      pixels[index] = 128;
    }
    return Uint8List.fromList(ZLibEncoder().convert(pixels));
  }
}
