import 'dart:math' as math;
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Works out the two 64-bit fingerprints that say whether two pictures look
/// alike.
///
/// Everything here is pure maths over a square grayscale grid, so it runs the
/// same on a phone and in a test with no device, no files, and no decoder.
/// Getting the grid is somebody else's job.
class PerceptualHashService {
  /// Side of the grid the hashes expect, normally 32.
  final int gridSize;

  /// Side of the DCT block kept, normally 8, giving 64 bits.
  final int blockSize;

  PerceptualHashService({
    this.gridSize = AppConstants.perceptualHashGridSize,
    this.blockSize = AppConstants.perceptualHashBlockSize,
  }) : assert(gridSize >= 8, 'The grid must be at least 8 by 8'),
       assert(blockSize == 8, 'A 64-bit hash needs an 8 by 8 block');

  /// The DCT perceptual hash of [grayscale].
  ///
  /// The grid is transformed, and only the top-left [blockSize] square of the
  /// result is kept: those are the slow, broad changes across the picture,
  /// which is exactly the part that survives a resize, a re-save, or a
  /// brightness change. The very first value is dropped because it is only
  /// the average brightness and would swamp the median. Each remaining value
  /// becomes one bit: 1 when it is above the median, 0 when it is not.
  ///
  /// Using the median, rather than a fixed number, is what makes the hash
  /// steady when a whole photo is made lighter or darker: every value moves
  /// together, so the comparison does not change.
  int computePHash(Uint8List grayscale) {
    final matrix = _toMatrix(grayscale);
    final dct = _dct2d(matrix);

    // Read the kept block, skipping the DC term at (0, 0).
    final values = <double>[];
    for (var y = 0; y < blockSize; y++) {
      for (var x = 0; x < blockSize; x++) {
        if (x == 0 && y == 0) continue;
        values.add(dct[y][x]);
      }
    }

    final median = _median(values);
    final tolerance = _tolerance(values);

    var hash = 0;
    var bit = 0;
    for (var y = 0; y < blockSize; y++) {
      for (var x = 0; x < blockSize; x++) {
        if (x == 0 && y == 0) {
          // The dropped DC term still takes a bit position, so both hashes
          // are a full 64 bits and always line up the same way.
          bit++;
          continue;
        }
        if (dct[y][x] > median + tolerance) hash |= 1 << bit;
        bit++;
      }
    }
    return hash;
  }

  /// How far above the median a value must be before its bit is set.
  ///
  /// Without this, a picture with little detail — a blank wall, a plain
  /// screenshot, a solid background — produces coefficients that are all
  /// mathematically zero, leaving the median sitting in floating-point noise
  /// around 1e-15. Which side of it each value falls on would then be decided
  /// by rounding error, so two identical flat pictures could hash completely
  /// differently while two unrelated ones happened to agree.
  ///
  /// Scaling the tolerance to the largest coefficient keeps it meaningless for
  /// a normal photo, where the values are in the hundreds, and decisive for a
  /// flat one, which now hashes to a stable zero.
  double _tolerance(List<double> values) {
    var largest = 0.0;
    for (final value in values) {
      final magnitude = value.abs();
      if (magnitude > largest) largest = magnitude;
    }
    return math.max(_absoluteTolerance, largest * _relativeTolerance);
  }

  /// Smallest tolerance used, so an all-zero block still resolves cleanly.
  static const double _absoluteTolerance = 1e-9;

  /// Tolerance as a fraction of the largest coefficient in the block.
  static const double _relativeTolerance = 1e-9;

  /// The difference hash of [grayscale].
  ///
  /// The grid is squeezed down to 9 columns by 8 rows, then each pixel is
  /// compared with the one to its right: 1 when it is brighter, 0 when it is
  /// not. That gives 8 x 8 = 64 bits describing which way the picture gets
  /// lighter as you move across it.
  ///
  /// It is far cheaper than the DCT hash and very good at spotting a resized
  /// or re-saved copy. It is weaker against a contrast change, which is why
  /// the two hashes are used together rather than either alone.
  int computeDHash(Uint8List grayscale) {
    const rows = 8;
    const columns = 9;
    final resized = _resizeGrid(grayscale, columns, rows);

    var hash = 0;
    var bit = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < rows; x++) {
        final left = resized[y * columns + x];
        final right = resized[y * columns + x + 1];
        if (left > right) hash |= 1 << bit;
        bit++;
      }
    }
    return hash;
  }

  /// How many bits differ between [a] and [b], from 0 to 64.
  ///
  /// This is the whole measure of "how alike". Zero means the fingerprints
  /// match exactly; a small number means the pictures look the same; a large
  /// number means they do not.
  static int hammingDistance(int a, int b) {
    var value = a ^ b;
    var count = 0;
    // Dart integers are 64-bit on the VM but 53-bit doubles on the web, and
    // this app is Android only, so a plain bit walk is both correct and easy
    // to read.
    for (var i = 0; i < 64; i++) {
      if ((value & 1) != 0) count++;
      value >>>= 1;
      if (value == 0) break;
    }
    return count;
  }

  /// Splits a hash into [bandCount] equal slices of bits.
  ///
  /// Two pictures that are close overall will very likely have at least one
  /// slice that matches exactly, so slices make cheap bucket keys: only
  /// pictures that share a slice need the full comparison. This is what keeps
  /// a scan of ten thousand photos from being a hundred million compares.
  static List<int> bands(
    int hash, {
    int bandCount = AppConstants.duplicateHashBandCount,
  }) {
    if (bandCount <= 0) return <int>[hash];
    final width = 64 ~/ bandCount;
    final mask = width >= 64 ? -1 : (1 << width) - 1;
    return <int>[
      for (var i = 0; i < bandCount; i++) (hash >>> (i * width)) & mask,
    ];
  }

  /// Turns the flat grayscale bytes into a square of doubles.
  List<List<double>> _toMatrix(Uint8List grayscale) {
    if (grayscale.length != gridSize * gridSize) {
      throw ArgumentError(
        'Expected ${gridSize * gridSize} grayscale bytes, '
        'got ${grayscale.length}',
      );
    }
    return <List<double>>[
      for (var y = 0; y < gridSize; y++)
        <double>[
          for (var x = 0; x < gridSize; x++)
            grayscale[y * gridSize + x].toDouble(),
        ],
    ];
  }

  /// A 2D type-II DCT, done as rows then columns.
  ///
  /// Only the first [blockSize] rows and columns of the answer are ever read,
  /// so the transform stops there instead of computing the full square. On a
  /// 32x32 grid that is a sixteenth of the work for exactly the same result.
  List<List<double>> _dct2d(List<List<double>> input) {
    final size = gridSize;
    final cosines = _cosineTable(size);

    // Rows first: every row is transformed, but only the first `blockSize`
    // frequencies of each are kept, because the column pass only reads those.
    final rowPass = List<List<double>>.generate(
      size,
      (_) => List<double>.filled(blockSize, 0),
    );
    for (var y = 0; y < size; y++) {
      final row = input[y];
      for (var u = 0; u < blockSize; u++) {
        final table = cosines[u];
        var sum = 0.0;
        for (var x = 0; x < size; x++) {
          sum += row[x] * table[x];
        }
        rowPass[y][u] = sum * _scale(u, size);
      }
    }

    // Then columns, again keeping only the low frequencies.
    final output = List<List<double>>.generate(
      blockSize,
      (_) => List<double>.filled(blockSize, 0),
    );
    for (var u = 0; u < blockSize; u++) {
      for (var v = 0; v < blockSize; v++) {
        final table = cosines[v];
        var sum = 0.0;
        for (var y = 0; y < size; y++) {
          sum += rowPass[y][u] * table[y];
        }
        output[v][u] = sum * _scale(v, size);
      }
    }
    return output;
  }

  /// `cos((2n + 1) * k * pi / 2N)` for every frequency and position needed.
  ///
  /// Built once per call rather than inside the loops, where the same handful
  /// of cosines would otherwise be recomputed thousands of times.
  List<List<double>> _cosineTable(int size) {
    return List<List<double>>.generate(blockSize, (k) {
      return List<double>.generate(size, (n) {
        return math.cos(((2 * n + 1) * k * math.pi) / (2 * size));
      });
    });
  }

  /// The orthonormal scale factor of the type-II DCT.
  double _scale(int index, int size) {
    return index == 0 ? math.sqrt(1 / size) : math.sqrt(2 / size);
  }

  /// Nearest-neighbour resample of the square grid to [columns] by [rows].
  ///
  /// Nearest neighbour is the right choice here and not a shortcut: the grid
  /// has already been smoothly downscaled by the decoder, so a second
  /// smoothing pass would only blur away the very edges the difference hash
  /// is looking for.
  Uint8List _resizeGrid(Uint8List grayscale, int columns, int rows) {
    if (grayscale.length != gridSize * gridSize) {
      throw ArgumentError(
        'Expected ${gridSize * gridSize} grayscale bytes, '
        'got ${grayscale.length}',
      );
    }
    final out = Uint8List(columns * rows);
    for (var y = 0; y < rows; y++) {
      final sourceY = ((y * gridSize) ~/ rows).clamp(0, gridSize - 1);
      for (var x = 0; x < columns; x++) {
        final sourceX = ((x * gridSize) ~/ columns).clamp(0, gridSize - 1);
        out[y * columns + x] = grayscale[sourceY * gridSize + sourceX];
      }
    }
    return out;
  }

  /// The middle value of [values], averaging the two middles when the count
  /// is even.
  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = <double>[...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
