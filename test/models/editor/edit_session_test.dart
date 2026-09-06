import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';

void main() {
  group('EditSession', () {
    test('a fresh session has changed nothing', () {
      final session = EditSession.initial('media-1');

      expect(session.mediaId, 'media-1');
      expect(session.isDirty, isFalse);
      expect(session.crop.isIdentity, isTrue);
      expect(session.tone.isNeutral, isTrue);
      expect(session.filter.isNone, isTrue);
      expect(session.watermark.isNone, isTrue);
      expect(session.markup, isEmpty);
      expect(session.redactions, isEmpty);
    });

    test('any tool touching the photo makes the session dirty', () {
      final base = EditSession.initial('media-1');

      expect(
        base.copyWith(tone: const ToneAdjustments(exposure: 0.2)).isDirty,
        isTrue,
      );
      expect(
        base
            .copyWith(filter: const FilterPreset(id: FilterPresetId.mono))
            .isDirty,
        isTrue,
      );
      expect(
        base.copyWith(crop: const CropTransform(quarterTurns: 1)).isDirty,
        isTrue,
      );
      expect(
        base
            .copyWith(
              watermark: const WatermarkConfig(
                mode: WatermarkMode.text,
                text: 'hello',
              ),
            )
            .isDirty,
        isTrue,
      );
    });

    test('a watermark with nothing in it is not a change', () {
      final session = EditSession.initial(
        'media-1',
      ).copyWith(watermark: const WatermarkConfig(mode: WatermarkMode.text));

      expect(session.isDirty, isFalse);
    });

    test('markup layers are added, replaced, and removed', () {
      const stroke = DoodleStroke(
        id: 'a',
        colorArgb: 0xFFFF0000,
        points: <NormalizedPoint>[NormalizedPoint(0, 0), NormalizedPoint(1, 1)],
      );

      final withLayer = EditSession.initial('media-1').addMarkup(stroke);
      expect(withLayer.markup, hasLength(1));

      final replaced = withLayer.replaceMarkup(
        stroke.copyWith(colorArgb: 0xFF00FF00),
      );
      expect(replaced.markup.single.colorArgb, 0xFF00FF00);

      expect(replaced.removeMarkup('a').markup, isEmpty);
      // Removing something that is not there leaves the list alone.
      expect(replaced.removeMarkup('missing').markup, hasLength(1));
    });

    test('redaction areas are added and removed', () {
      const region = RedactionRegion(
        id: 'r1',
        rect: NormalizedRect(left: 0.1, top: 0.1, right: 0.4, bottom: 0.4),
      );

      final session = EditSession.initial('media-1').addRedaction(region);
      expect(session.redactions, hasLength(1));
      expect(session.isDirty, isTrue);
      expect(session.removeRedaction('r1').redactions, isEmpty);
    });

    test('reset clears everything but keeps the media id', () {
      final session = EditSession.initial('media-1')
          .copyWith(tone: const ToneAdjustments(contrast: 0.5))
          .addRedaction(
            const RedactionRegion(id: 'r1', rect: NormalizedRect.full),
          );

      final cleared = session.reset();

      expect(cleared.mediaId, 'media-1');
      expect(cleared.isDirty, isFalse);
    });

    test('survives a round trip through JSON', () {
      final session = EditSession.initial('media-1')
          .copyWith(
            crop: const CropTransform(
              quarterTurns: 2,
              straightenDegrees: 3.5,
              rect: NormalizedRect(
                left: 0.1,
                top: 0.2,
                right: 0.8,
                bottom: 0.9,
              ),
            ),
            tone: const ToneAdjustments(exposure: 0.3, vibrance: -0.2),
            filter: const FilterPreset(
              id: FilterPresetId.sepia,
              intensity: 0.5,
            ),
            watermark: const WatermarkConfig(
              mode: WatermarkMode.timestamp,
              position: WatermarkPosition.topLeft,
            ),
          )
          .addMarkup(
            const ShapeAnnotation(
              id: 's1',
              colorArgb: 0xFF00FF00,
              shape: ShapeKind.arrow,
              start: NormalizedPoint(0.1, 0.1),
              end: NormalizedPoint(0.6, 0.6),
            ),
          )
          .addRedaction(
            const RedactionRegion(
              id: 'r1',
              rect: NormalizedRect(
                left: 0.2,
                top: 0.2,
                right: 0.5,
                bottom: 0.5,
              ),
              mode: RedactionMode.pixelate,
            ),
          );

      expect(EditSession.fromJson(session.toJson()), session);
    });

    test(
      'a corrupt stored session becomes a blank one instead of throwing',
      () {
        final session = EditSession.fromJson('this is not json');

        expect(session.mediaId, isEmpty);
        expect(session.isDirty, isFalse);
      },
    );

    test('an unreadable markup layer is dropped, not fatal', () {
      final session = EditSession.fromMap(<String, dynamic>{
        'mediaId': 'media-1',
        'markup': <dynamic>[
          <String, dynamic>{'kind': 'from-a-newer-build'},
          <String, dynamic>{
            'kind': 'text',
            'id': 't1',
            'text': 'keep me',
            'colorArgb': 0xFFFFFFFF,
          },
        ],
      });

      expect(session.markup, hasLength(1));
      expect((session.markup.single as TextAnnotation).text, 'keep me');
    });
  });
}
