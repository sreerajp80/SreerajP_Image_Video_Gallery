import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/sized_memory_image.dart';

void main() {
  group('decodeSize', () {
    test('a contain fit decodes at the box size in physical pixels', () {
      final size = SizedMemoryImage.decodeSize(
        boxWidth: 100,
        boxHeight: 50,
        pixelRatio: 3,
        fit: BoxFit.contain,
      );
      expect(size, (width: 300, height: 150));
    });

    test('a cover fit doubles the box so a 2:1 photo stays sharp', () {
      final size = SizedMemoryImage.decodeSize(
        boxWidth: 64,
        boxHeight: 64,
        pixelRatio: 2.5,
        fit: BoxFit.cover,
      );
      expect(size, (width: 320, height: 320));
    });

    test('an unbounded box decodes the image as it is', () {
      expect(
        SizedMemoryImage.decodeSize(
          boxWidth: double.infinity,
          boxHeight: 64,
          pixelRatio: 2,
          fit: BoxFit.cover,
        ),
        isNull,
      );
    });
  });

  testWidgets('a sized tile asks for a resized image', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2),
        child: Center(
          child: SizedMemoryImage(
            Uint8List.fromList(<int>[0]),
            width: 64,
            height: 64,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    final resize = image.image as ResizeImage;
    expect(resize.width, 256);
    expect(resize.height, 256);
    expect(resize.policy, ResizeImagePolicy.fit);
  });
}
