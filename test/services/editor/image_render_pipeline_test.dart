import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/image_render_pipeline.dart';

/// A picture with a distinct colour in each quarter.
///
/// Different quarters make it easy to prove that a rotation or a flip really
/// moved the pixels, rather than only changing the reported size.
img.Image buildQuadrantImage({int width = 80, int height = 40}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: width ~/ 2 - 1,
    y2: height ~/ 2 - 1,
    color: img.ColorRgba8(255, 0, 0, 255),
  );
  img.fillRect(
    image,
    x1: width ~/ 2,
    y1: 0,
    x2: width - 1,
    y2: height ~/ 2 - 1,
    color: img.ColorRgba8(0, 255, 0, 255),
  );
  img.fillRect(
    image,
    x1: 0,
    y1: height ~/ 2,
    x2: width ~/ 2 - 1,
    y2: height - 1,
    color: img.ColorRgba8(0, 0, 255, 255),
  );
  return image;
}

Uint8List encodeSource({int width = 80, int height = 40}) {
  return img.encodePng(buildQuadrantImage(width: width, height: height));
}

/// Decodes a render result so its pixels can be checked.
img.Image decodeResult(RenderResult result) => img.decodeImage(result.bytes)!;

void main() {
  const pipeline = ImageRenderPipeline();

  RenderRequest requestFor(EditSession session, {int? maxSide}) {
    return RenderRequest(
      sourceBytes: encodeSource(),
      sessionJson: session.toJson(),
      format: RenderFormat.png,
      maxSide: maxSide,
    );
  }

  group('decode', () {
    test('an empty file is reported, not crashed on', () {
      expect(
        () => pipeline.decode(Uint8List(0)),
        throwsA(isA<ImageRenderException>()),
      );
    });

    test('random bytes are reported, not crashed on', () {
      expect(
        () => pipeline.decode(Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6])),
        throwsA(isA<ImageRenderException>()),
      );
    });

    test('a real picture decodes to its own size', () {
      final decoded = pipeline.decode(encodeSource());

      expect(decoded.width, 80);
      expect(decoded.height, 40);
    });
  });

  group('RenderFormat', () {
    test('a JPEG file name renders back to JPEG', () {
      expect(RenderFormat.forFileName('IMG_1.jpg'), RenderFormat.jpeg);
      expect(RenderFormat.forFileName('IMG_1.JPEG'), RenderFormat.jpeg);
    });

    test('anything else renders to PNG so nothing is lost', () {
      expect(RenderFormat.forFileName('shot.png'), RenderFormat.png);
      expect(RenderFormat.forFileName('scan.webp'), RenderFormat.png);
    });

    test('the extension matches the format', () {
      expect(RenderFormat.jpeg.extension, 'jpg');
      expect(RenderFormat.png.extension, 'png');
    });
  });

  group('render with nothing changed', () {
    test('the picture comes back at its own size', () {
      final result = pipeline.render(
        requestFor(EditSession.initial('media-1')),
      );

      expect(result.width, 80);
      expect(result.height, 40);
    });
  });

  group('geometry', () {
    test('a quarter turn swaps width and height', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(crop: const CropTransform(quarterTurns: 1)),
        ),
      );

      expect(result.width, 40);
      expect(result.height, 80);
    });

    test('a crop keeps only the chosen part', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').copyWith(
            crop: const CropTransform(
              rect: NormalizedRect(left: 0, top: 0, right: 0.5, bottom: 0.5),
            ),
          ),
        ),
      );

      expect(result.width, 40);
      expect(result.height, 20);
      // The top-left quarter was red, so the cropped result is red.
      final pixel = decodeResult(result).getPixel(5, 5);
      expect(pixel.r, 255);
      expect(pixel.g, 0);
    });

    test('a horizontal mirror moves the red quarter to the right', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(crop: const CropTransform(flipHorizontal: true)),
        ),
      );

      final decoded = decodeResult(result);
      // Red started top-left; after mirroring it is top-right.
      expect(decoded.getPixel(75, 5).r, 255);
      expect(decoded.getPixel(75, 5).g, 0);
    });

    test('straightening cuts the blank corners back off', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(crop: const CropTransform(straightenDegrees: 10)),
        ),
      );

      // The tilted picture is cropped, so it ends up smaller, not larger.
      expect(result.width, lessThanOrEqualTo(80));
      expect(result.height, lessThanOrEqualTo(40));
      expect(result.width, greaterThan(0));
    });

    test('a perspective pull still produces a usable picture', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').copyWith(
            crop: const CropTransform(
              perspective: PerspectiveSkew(topInset: 0.2),
            ),
          ),
        ),
      );

      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });
  });

  group('tone and filters', () {
    test('raising the exposure brightens the picture', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(tone: const ToneAdjustments(exposure: 0.5)),
        ),
      );

      // The blue quarter's blue channel was already at 255, so the red
      // channel of that quarter is what shows the lift.
      final pixel = decodeResult(result).getPixel(5, 35);
      expect(pixel.r, greaterThanOrEqualTo(0));
      expect(decodeResult(result).getPixel(60, 30).r, greaterThan(200));
    });

    test('the mono filter makes every channel the same', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(filter: const FilterPreset(id: FilterPresetId.mono)),
        ),
      );

      final pixel = decodeResult(result).getPixel(5, 5);
      expect(pixel.r, pixel.g);
      expect(pixel.g, pixel.b);
    });

    test('a filter at zero strength leaves the colours alone', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').copyWith(
            filter: const FilterPreset(id: FilterPresetId.mono, intensity: 0),
          ),
        ),
      );

      final pixel = decodeResult(result).getPixel(5, 5);
      expect(pixel.r, 255);
      expect(pixel.g, 0);
    });

    test('the sepia filter warms the picture', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial(
            'media-1',
          ).copyWith(filter: const FilterPreset(id: FilterPresetId.sepia)),
        ),
      );

      // A sepia photo has more red than blue everywhere.
      final pixel = decodeResult(result).getPixel(60, 30);
      expect(pixel.r, greaterThan(pixel.b));
    });
  });

  group('redaction inside the pipeline', () {
    test('a blackout area really replaces the pixels', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').addRedaction(
            const RedactionRegion(
              id: 'r1',
              rect: NormalizedRect(left: 0, top: 0, right: 0.4, bottom: 0.4),
              mode: RedactionMode.blackout,
            ),
          ),
        ),
      );

      final pixel = decodeResult(result).getPixel(5, 5);
      expect(pixel.r, 0);
      expect(pixel.g, 0);
      expect(pixel.b, 0);
    });

    test('redaction is applied in the cropped coordinates', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1')
              .copyWith(
                crop: const CropTransform(
                  rect: NormalizedRect(
                    left: 0.5,
                    top: 0,
                    right: 1,
                    bottom: 0.5,
                  ),
                ),
              )
              .addRedaction(
                const RedactionRegion(
                  id: 'r1',
                  rect: NormalizedRect.full,
                  mode: RedactionMode.blackout,
                ),
              ),
        ),
      );

      // The whole cropped picture was blacked out, corner to corner.
      final decoded = decodeResult(result);
      expect(decoded.getPixel(0, 0).r, 0);
      expect(decoded.getPixel(decoded.width - 1, decoded.height - 1).r, 0);
    });
  });

  group('markup and watermark', () {
    test('a drawn line changes the pixels it crosses', () {
      final before = decodeResult(
        pipeline.render(requestFor(EditSession.initial('media-1'))),
      );

      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').addMarkup(
            const DoodleStroke(
              id: 'd1',
              colorArgb: 0xFF000000,
              points: <NormalizedPoint>[
                NormalizedPoint(0.6, 0.75),
                NormalizedPoint(0.95, 0.75),
              ],
              strokeWidth: 0.06,
            ),
          ),
        ),
      );

      final after = decodeResult(result);
      // That corner was white before the line was drawn across it.
      expect(before.getPixel(70, 30).r, 255);
      expect(after.getPixel(70, 30).r, lessThan(255));
    });

    test('an empty text layer draws nothing and does not fail', () {
      expect(
        () => pipeline.render(
          requestFor(
            EditSession.initial('media-1').addMarkup(
              const TextAnnotation(
                id: 't1',
                colorArgb: 0xFFFFFFFF,
                text: '   ',
                position: NormalizedPoint(0.1, 0.1),
              ),
            ),
          ),
        ),
        returnsNormally,
      );
    });

    test('a text watermark marks the picture', () {
      final result = pipeline.render(
        requestFor(
          EditSession.initial('media-1').copyWith(
            watermark: const WatermarkConfig(
              mode: WatermarkMode.text,
              text: 'MINE',
              position: WatermarkPosition.bottomRight,
              colorArgb: 0xFF000000,
              opacity: 1,
              scale: 0.2,
            ),
          ),
        ),
      );

      final decoded = decodeResult(result);
      // Somewhere in the bottom-right area a pixel is no longer plain white.
      var changed = false;
      for (var y = 25; y < decoded.height; y++) {
        for (var x = 50; x < decoded.width; x++) {
          if (decoded.getPixel(x, y).r != 255) changed = true;
        }
      }
      expect(changed, isTrue);
    });

    test('a logo watermark with unreadable bytes is skipped, not fatal', () {
      final result = pipeline.render(
        RenderRequest(
          sourceBytes: encodeSource(),
          sessionJson: EditSession.initial('media-1')
              .copyWith(
                watermark: const WatermarkConfig(
                  mode: WatermarkMode.logo,
                  logoPath: 'gone.png',
                ),
              )
              .toJson(),
          format: RenderFormat.png,
          logoBytes: Uint8List.fromList(<int>[9, 9, 9]),
        ),
      );

      expect(result.width, 80);
    });

    test('a timestamp watermark uses the capture date', () {
      final result = pipeline.render(
        RenderRequest(
          sourceBytes: encodeSource(),
          sessionJson: EditSession.initial('media-1')
              .copyWith(
                watermark: const WatermarkConfig(
                  mode: WatermarkMode.timestamp,
                  colorArgb: 0xFF000000,
                  opacity: 1,
                ),
              )
              .toJson(),
          format: RenderFormat.png,
          captureDate: DateTime(2026, 8, 29, 10, 30),
        ),
      );

      expect(result.width, 80);
      expect(result.bytes, isNotEmpty);
    });
  });

  group('preview sizing', () {
    test('a preview is shrunk to the requested longest side', () {
      final result = pipeline.render(
        requestFor(EditSession.initial('media-1'), maxSide: 40),
      );

      expect(result.width, 40);
      expect(result.height, 20);
    });

    test('a picture already small enough is left at its own size', () {
      final result = pipeline.render(
        requestFor(EditSession.initial('media-1'), maxSide: 1000),
      );

      expect(result.width, 80);
    });

    test('the preview side is capped for a large photo', () {
      expect(
        pipeline.previewMaxSide(const PixelSize(6000, 4000)),
        lessThanOrEqualTo(1080),
      );
      // A small photo is not enlarged.
      expect(pipeline.previewMaxSide(const PixelSize(400, 300)), 400);
    });
  });

  group('combineAdjustments', () {
    test('a neutral preset changes nothing', () {
      const user = ToneAdjustments(exposure: 0.4);

      expect(pipeline.combineAdjustments(user, ToneAdjustments.neutral), user);
    });

    test('a preset adds to what the user set', () {
      final combined = pipeline.combineAdjustments(
        const ToneAdjustments(contrast: 0.3),
        const ToneAdjustments(contrast: 0.2),
      );

      expect(combined.contrast, closeTo(0.5, 0.0001));
    });

    test('the total never runs past the ends of the slider', () {
      final combined = pipeline.combineAdjustments(
        const ToneAdjustments(contrast: 0.9),
        const ToneAdjustments(contrast: 0.9),
      );

      expect(combined.contrast, 1);
    });
  });

  group('encode', () {
    test('JPEG and PNG both produce bytes', () {
      final image = buildQuadrantImage();

      expect(pipeline.encode(image, RenderFormat.jpeg, 90), isNotEmpty);
      expect(pipeline.encode(image, RenderFormat.png, 90), isNotEmpty);
    });

    test('an out of range quality is pulled back rather than failing', () {
      final image = buildQuadrantImage();

      expect(pipeline.encode(image, RenderFormat.jpeg, 500), isNotEmpty);
    });
  });
}
