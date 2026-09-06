import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/perceptual_hash_service.dart';

/// Builds a 32x32 grid from a function of the pixel position.
Uint8List grid(int Function(int x, int y) shade, {int size = 32}) {
  final out = Uint8List(size * size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      out[y * size + x] = shade(x, y).clamp(0, 255);
    }
  }
  return out;
}

void main() {
  final service = PerceptualHashService();

  group('hammingDistance', () {
    test('a value against itself is zero', () {
      expect(PerceptualHashService.hammingDistance(0x0F0F0F0F, 0x0F0F0F0F), 0);
    });

    test('counts only the bits that differ', () {
      expect(PerceptualHashService.hammingDistance(0x0, 0x7), 3);
      expect(PerceptualHashService.hammingDistance(0xFF, 0xF0), 4);
    });

    test('handles a hash with the top bit set', () {
      // A 64-bit hash with bit 63 set is a negative Dart integer, so this
      // would be the first thing to break if the shifting were signed.
      final high = 1 << 63;
      expect(PerceptualHashService.hammingDistance(high, 0), 1);
      expect(PerceptualHashService.hammingDistance(high, high), 0);
      expect(PerceptualHashService.hammingDistance(high, high | 1), 1);
    });
  });

  group('dHash', () {
    test('a left-to-right ramp sets no bits', () {
      // Every pixel is darker than the one to its right, so no comparison is
      // ever "brighter than the neighbour".
      final hash = service.computeDHash(grid((x, y) => x * 8));

      expect(hash, 0);
    });

    test('a right-to-left ramp sets every bit', () {
      final hash = service.computeDHash(grid((x, y) => 255 - x * 8));

      // All 64 bits set, which as a signed 64-bit integer is -1.
      expect(hash, -1);
    });

    test('a flat grid sets no bits', () {
      expect(service.computeDHash(grid((x, y) => 128)), 0);
    });

    test('two pictures that differ across a row give different hashes', () {
      final a = service.computeDHash(grid((x, y) => x * 8));
      final b = service.computeDHash(grid((x, y) => (x * 37) % 256));

      expect(a, isNot(b));
    });

    test('purely vertical structure is invisible to it', () {
      // The difference hash only ever compares a pixel with the one to its
      // right, so a top-to-bottom ramp reads the same as a flat grid. This is
      // a known blind spot, and the reason the DCT hash is computed as well
      // rather than trusting this one alone.
      expect(service.computeDHash(grid((x, y) => y * 8)), 0);
      expect(service.computeDHash(grid((x, y) => 128)), 0);
    });

    test('rejects a grid of the wrong size', () {
      expect(
        () => service.computeDHash(Uint8List(10)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('pHash', () {
    test('the same picture always gives the same hash', () {
      // A wavy pattern rather than a straight ramp, so the picture has real
      // detail at several frequencies the way a photograph does.
      int shade(int x, int y) =>
          (128 + 90 * math.sin(x / 4) * math.cos(y / 6)).round();

      expect(
        service.computePHash(grid(shade)),
        service.computePHash(grid(shade)),
      );
      expect(service.computePHash(grid(shade)), isNot(0));
    });

    test('brightening every pixel leaves the hash alone', () {
      // This is the whole point of comparing against the median rather than a
      // fixed level: a lighter copy of a photo is still the same photo.
      final original = grid((x, y) => (x * 4 + y * 2) % 200);
      final brighter = grid((x, y) => ((x * 4 + y * 2) % 200) + 40);

      expect(service.computePHash(brighter), service.computePHash(original));
    });

    test('a flat picture hashes to a stable zero, not to noise', () {
      // A blank wall or a plain background has no detail at all, so every
      // coefficient is zero and the median sits in floating-point noise.
      // Without a tolerance the bits would be decided by rounding error and
      // two photos of the same blank wall would look unrelated.
      expect(service.computePHash(grid((x, y) => 128)), 0);
      expect(service.computePHash(grid((x, y) => 200)), 0);
    });

    test('a small shift stays close, an unrelated picture does not', () {
      final original = grid(
        (x, y) => (128 + 100 * math.sin(x / 5) * math.cos(y / 7)).round(),
      );
      final shifted = grid(
        (x, y) =>
            (128 + 100 * math.sin((x + 1) / 5) * math.cos((y + 1) / 7)).round(),
      );
      final unrelated = grid((x, y) => (x * y) % 256);

      final shiftDistance = PerceptualHashService.hammingDistance(
        service.computePHash(original),
        service.computePHash(shifted),
      );
      final unrelatedDistance = PerceptualHashService.hammingDistance(
        service.computePHash(original),
        service.computePHash(unrelated),
      );

      // A one-pixel shift on a 32-wide grid is a real change, so the point
      // is not that the distance is tiny but that it is clearly smaller than
      // the distance to a picture with nothing in common.
      expect(shiftDistance, lessThan(unrelatedDistance));
      expect(unrelatedDistance, greaterThan(20));
    });

    test('the DC bit is never set, so both hashes line up the same way', () {
      // Bit 0 stands for the dropped average-brightness term.
      final hash = service.computePHash(grid((x, y) => (x * 7) % 256));

      expect(hash & 1, 0);
    });

    test('rejects a grid of the wrong size', () {
      expect(
        () => service.computePHash(Uint8List(100)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('bands', () {
    test('splits a hash into equal slices that rebuild it', () {
      const hash = 0x1234567890ABCDEF;
      final bands = PerceptualHashService.bands(hash, bandCount: 4);

      expect(bands.length, 4);
      var rebuilt = 0;
      for (var i = 0; i < bands.length; i++) {
        rebuilt |= bands[i] << (i * 16);
      }
      expect(rebuilt, hash);
    });

    test('identical hashes share every band', () {
      const hash = 0x00FF00FF00FF00FF;
      expect(
        PerceptualHashService.bands(hash),
        PerceptualHashService.bands(hash),
      );
    });

    test('a hash differing in one band still shares the others', () {
      const a = 0x1111222233334444;
      const b = 0x1111222233335555;

      final bandsA = PerceptualHashService.bands(a);
      final bandsB = PerceptualHashService.bands(b);
      final shared = <int>[
        for (var i = 0; i < bandsA.length; i++)
          if (bandsA[i] == bandsB[i]) i,
      ];

      // The point of banding: near-identical hashes still land in a common
      // bucket, so they get compared properly.
      expect(shared, isNotEmpty);
    });
  });
}
