import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';

EditSessionNotifier buildNotifier() => EditSessionNotifier(
  mediaId: 'media-1',
  cropService: const CropTransformService(),
);

void main() {
  group('EditSessionNotifier history', () {
    test('a new notifier has nothing to undo or redo', () {
      final notifier = buildNotifier();

      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isFalse);
      expect(notifier.state.isDirty, isFalse);
    });

    test('a change can be undone and then redone', () {
      final notifier = buildNotifier();

      notifier.setTone(const ToneAdjustments(exposure: 0.5));
      expect(notifier.state.tone.exposure, 0.5);
      expect(notifier.canUndo, isTrue);

      notifier.undo();
      expect(notifier.state.tone.exposure, 0);
      expect(notifier.canRedo, isTrue);

      notifier.redo();
      expect(notifier.state.tone.exposure, 0.5);
    });

    test('a change that alters nothing is not recorded', () {
      final notifier = buildNotifier();

      notifier.setTone(ToneAdjustments.neutral);

      expect(notifier.canUndo, isFalse);
    });

    test('a new change ends the redo branch', () {
      final notifier = buildNotifier();

      notifier.setTone(const ToneAdjustments(exposure: 0.5));
      notifier.undo();
      expect(notifier.canRedo, isTrue);

      notifier.setTone(const ToneAdjustments(contrast: 0.2));

      expect(notifier.canRedo, isFalse);
      expect(notifier.state.tone.contrast, 0.2);
    });

    test('the history stops growing at the configured depth', () {
      final notifier = buildNotifier();

      for (var i = 1; i <= AppConstants.editorUndoDepth + 10; i++) {
        notifier.setTone(ToneAdjustments(exposure: i / 1000));
      }

      var steps = 0;
      while (notifier.canUndo) {
        notifier.undo();
        steps++;
        // A runaway history would loop here rather than stopping.
        if (steps > AppConstants.editorUndoDepth + 50) break;
      }

      expect(steps, lessThanOrEqualTo(AppConstants.editorUndoDepth));
    });

    test('undo and redo do nothing when there is nothing to do', () {
      final notifier = buildNotifier();
      final before = notifier.state;

      notifier.undo();
      notifier.redo();

      expect(notifier.state, before);
    });
  });

  group('EditSessionNotifier crop tools', () {
    test('a crop dragged outside the image is corrected', () {
      final notifier = buildNotifier();

      notifier.setCropRect(
        const NormalizedRect(left: -1, top: -1, right: 2, bottom: 2),
      );

      expect(notifier.state.crop.rect, NormalizedRect.full);
    });

    test('quarter turns wrap round after four', () {
      final notifier = buildNotifier();

      for (var i = 0; i < 4; i++) {
        notifier.rotateQuarter();
      }

      expect(notifier.state.crop.quarterTurns, 0);
    });

    test('turning left from zero gives three quarter turns', () {
      final notifier = buildNotifier();

      notifier.rotateQuarter(clockwise: false);

      expect(notifier.state.crop.quarterTurns, 3);
    });

    test('the straighten angle is held inside the slider range', () {
      final notifier = buildNotifier();

      notifier.setStraighten(120);

      expect(
        notifier.state.crop.straightenDegrees,
        AppConstants.editorStraightenMaxDegrees,
      );
    });

    test('an aspect preset reshapes the crop box', () {
      final notifier = buildNotifier();

      notifier.setAspectPreset(
        CropAspectPreset.square,
        const PixelSize(1000, 500),
      );

      final rect = notifier.state.crop.rect;
      expect(notifier.state.crop.aspectPreset, CropAspectPreset.square);
      expect(rect.isValid, isTrue);
      // A square on a 2:1 image is half as wide as it is tall, in fractions.
      expect(rect.width, closeTo(rect.height / 2, 0.01));
    });

    test('the mirrors toggle on and off', () {
      final notifier = buildNotifier();

      notifier.toggleFlipHorizontal();
      expect(notifier.state.crop.flipHorizontal, isTrue);

      notifier.toggleFlipHorizontal();
      expect(notifier.state.crop.flipHorizontal, isFalse);
    });

    test('the perspective pull is held inside the supported range', () {
      final notifier = buildNotifier();

      notifier.setPerspective(const PerspectiveSkew(topInset: 9));

      expect(
        notifier.state.crop.perspective.topInset,
        AppConstants.editorPerspectiveMaxInset,
      );
    });

    test('resetting the crop leaves the other tools alone', () {
      final notifier = buildNotifier();

      notifier.setTone(const ToneAdjustments(exposure: 0.4));
      notifier.rotateQuarter();
      notifier.resetCrop();

      expect(notifier.state.crop.isIdentity, isTrue);
      expect(notifier.state.tone.exposure, 0.4);
    });
  });

  group('EditSessionNotifier layer tools', () {
    const stroke = DoodleStroke(
      id: 'd1',
      colorArgb: 0xFFFF0000,
      points: <NormalizedPoint>[NormalizedPoint(0, 0), NormalizedPoint(1, 1)],
    );

    test('markup is added and the last one can be removed', () {
      final notifier = buildNotifier();

      notifier.addMarkup(stroke);
      notifier.addMarkup(stroke.copyWith(id: 'd2'));
      expect(notifier.state.markup, hasLength(2));

      notifier.removeLastMarkup();
      expect(notifier.state.markup.single.id, 'd1');
    });

    test('removing the last markup on an empty list does nothing', () {
      final notifier = buildNotifier();

      notifier.removeLastMarkup();

      expect(notifier.canUndo, isFalse);
    });

    test('a redaction area is added and removed', () {
      final notifier = buildNotifier();

      notifier.addRedaction(
        const RedactionRegion(id: 'r1', rect: NormalizedRect.full),
      );
      expect(notifier.state.redactions, hasLength(1));

      notifier.removeRedaction('r1');
      expect(notifier.state.redactions, isEmpty);
    });

    test('the filter and watermark are replaced whole', () {
      final notifier = buildNotifier();

      notifier.setFilter(const FilterPreset(id: FilterPresetId.vivid));
      notifier.setWatermark(
        const WatermarkConfig(mode: WatermarkMode.timestamp),
      );

      expect(notifier.state.filter.id, FilterPresetId.vivid);
      expect(notifier.state.watermark.mode, WatermarkMode.timestamp);
    });

    test('reset all clears everything and can itself be undone', () {
      final notifier = buildNotifier();

      notifier.setTone(const ToneAdjustments(exposure: 0.5));
      notifier.addMarkup(stroke);
      notifier.resetAll();

      expect(notifier.state.isDirty, isFalse);

      notifier.undo();
      expect(notifier.state.markup, hasLength(1));
    });
  });

  group('PreviewRequest', () {
    test('it is the same request only when the edit is the same', () {
      final notifier = buildNotifier();
      final first = notifier.state;

      notifier.setTone(const ToneAdjustments(exposure: 0.2));
      final second = notifier.state;

      expect(first == second, isFalse);
    });
  });
}
