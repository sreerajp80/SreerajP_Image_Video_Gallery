import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/media_hashes.dart';

void main() {
  group('MediaHashes state', () {
    test('hasAny is false only when nothing was worked out', () {
      expect(const MediaHashes(mediaId: 'a').hasAny, isFalse);
      expect(const MediaHashes(mediaId: 'a', sha256: 'x').hasAny, isTrue);
      expect(const MediaHashes(mediaId: 'a', pHash: 1).hasAny, isTrue);
    });

    test('hasPerceptual needs both hashes', () {
      expect(const MediaHashes(mediaId: 'a', pHash: 1).hasPerceptual, isFalse);
      expect(
        const MediaHashes(mediaId: 'a', pHash: 1, dHash: 2).hasPerceptual,
        isTrue,
      );
    });

    test('copyWith and equality behave', () {
      const original = MediaHashes(mediaId: 'a', sha256: 'x', pHash: 1);

      expect(original.copyWith(), original);
      expect(original.copyWith(sha256: 'y').sha256, 'y');
      expect(original.copyWith(sha256: 'y'), isNot(original));
      expect(original.hashCode, original.copyWith().hashCode);
    });
  });

  group('perceptual hash encoding', () {
    test('a 64-bit value survives a round trip', () {
      const value = 0x1234567890ABCDEF;

      expect(MediaHashes.fromHex64(MediaHashes.toHex64(value)), value);
    });

    test('a value with the top bit set survives a round trip', () {
      // Such a hash is a negative Dart integer. Asking it directly for a hex
      // string would produce a minus sign and lose the bit pattern, so this is
      // the case the two-halves encoding exists for.
      final value = 1 << 63;

      expect(MediaHashes.toHex64(value).length, 16);
      expect(MediaHashes.toHex64(value).startsWith('-'), isFalse);
      expect(MediaHashes.fromHex64(MediaHashes.toHex64(value)), value);
      expect(MediaHashes.fromHex64(MediaHashes.toHex64(-1)), -1);
    });

    test('encodes both hashes into the one column', () {
      const hashes = MediaHashes(mediaId: 'a', pHash: 0xFF, dHash: 0xEE);

      expect(hashes.encodedPerceptual, '00000000000000ff:00000000000000ee');
    });

    test('encodes just the pHash when there is no dHash', () {
      const hashes = MediaHashes(mediaId: 'a', pHash: 0xFF);

      expect(hashes.encodedPerceptual, '00000000000000ff');
    });

    test('nothing to encode gives null', () {
      expect(const MediaHashes(mediaId: 'a').encodedPerceptual, isNull);
    });

    test('decode reads back what encode wrote', () {
      const hashes = MediaHashes(
        mediaId: 'a',
        pHash: 0x1122334455667788,
        dHash: 0x8877665544332211,
      );

      final decoded = MediaHashes.decodePerceptual(hashes.encodedPerceptual);

      expect(decoded.pHash, hashes.pHash);
      expect(decoded.dHash, hashes.dHash);
    });

    test('decode copes with missing and malformed stored text', () {
      expect(MediaHashes.decodePerceptual(null).pHash, isNull);
      expect(MediaHashes.decodePerceptual('').pHash, isNull);
      expect(MediaHashes.decodePerceptual('not-hex-at-all').pHash, isNull);
      // Too short to be a 64-bit hash, so it is not guessed at.
      expect(MediaHashes.decodePerceptual('ff').pHash, isNull);
    });

    test('fromColumns rebuilds hashes from the two database columns', () {
      final hashes = MediaHashes.fromColumns(
        mediaId: 'a',
        sha256: 'abc',
        storedPerceptual: '00000000000000ff:00000000000000ee',
      );

      expect(hashes.sha256, 'abc');
      expect(hashes.pHash, 0xFF);
      expect(hashes.dHash, 0xEE);
    });

    test('fromColumns treats an empty digest as no digest', () {
      final hashes = MediaHashes.fromColumns(mediaId: 'a', sha256: '');

      expect(hashes.sha256, isNull);
      expect(hashes.hasAny, isFalse);
    });
  });
}
