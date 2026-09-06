import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_action_rules.dart';

const _rules = BatchActionRules();

MediaItem _item(String id, MediaType type) => MediaItem(
  id: id,
  path: '/storage/$id',
  displayName: id,
  mediaType: type,
  mimeType: 'application/octet-stream',
  size: 100,
  dateAdded: DateTime(2026, 1, 1),
  dateModified: DateTime(2026, 1, 1),
);

final _photo = _item('photo', MediaType.image);
final _video = _item('video', MediaType.video);
final _gif = _item('gif', MediaType.gif);
final _raw = _item('raw', MediaType.rawImage);
final _svg = _item('svg', MediaType.svg);

void main() {
  group('an empty selection allows nothing', () {
    test('every action is blocked, with the same reason', () {
      for (final result in _rules.evaluateAll(const <MediaItem>[])) {
        expect(result.isAllowed, isFalse, reason: result.action.name);
        expect(result.blockReason, BatchBlockReason.emptySelection);
      }
    });
  });

  group('actions that work on anything', () {
    test('tagging, albums, favourites, vault, transfer and trash all run', () {
      final mixed = <MediaItem>[_photo, _video, _gif, _raw, _svg];

      for (final action in <BatchAction>[
        BatchAction.addTags,
        BatchAction.removeTags,
        BatchAction.addToAlbum,
        BatchAction.favourite,
        BatchAction.unfavourite,
        BatchAction.moveToVault,
        BatchAction.transfer,
        BatchAction.moveToTrash,
      ]) {
        final result = _rules.evaluate(action, mixed);
        expect(result.isAllowed, isTrue, reason: action.name);
        expect(result.applicableCount, 5);
        expect(result.skippedCount, 0);
      }
    });
  });

  group('actions that need a picture', () {
    test('convert and watermark refuse a selection holding a video', () {
      // They need every item to be an image, so a mixed selection is refused
      // whole rather than quietly done in part.
      for (final action in <BatchAction>[
        BatchAction.convert,
        BatchAction.watermark,
      ]) {
        final result = _rules.evaluate(action, <MediaItem>[_photo, _video]);

        expect(result.isAllowed, isFalse, reason: action.name);
        expect(result.blockReason, BatchBlockReason.mixedTypes);
        expect(result.applicableCount, 1);
        expect(result.skippedCount, 1);
      }
    });

    test('convert runs on photos, GIFs and RAW together', () {
      final result = _rules.evaluate(BatchAction.convert, <MediaItem>[
        _photo,
        _gif,
        _raw,
      ]);

      expect(result.isAllowed, isTrue);
      expect(result.applicableCount, 3);
    });

    test('SVG is not something the pixel pipeline should re-encode', () {
      final result = _rules.evaluate(BatchAction.convert, <MediaItem>[_svg]);

      expect(result.isAllowed, isFalse);
      expect(result.blockReason, BatchBlockReason.noSupportedItems);
    });

    test('a selection of only videos blocks with "nothing supported"', () {
      final result = _rules.evaluate(BatchAction.watermark, <MediaItem>[
        _video,
        _video,
      ]);

      expect(result.blockReason, BatchBlockReason.noSupportedItems);
    });
  });

  group('PDF export takes a mixed selection', () {
    test('runs, and says how many it will pass over', () {
      // "Make a PDF of these photos" is a reasonable thing to mean even when
      // a video is caught in the selection.
      final result = _rules.evaluate(BatchAction.exportPdf, <MediaItem>[
        _photo,
        _video,
        _gif,
      ]);

      expect(result.isAllowed, isTrue);
      expect(result.applicableCount, 2);
      expect(result.skippedCount, 1);
      expect(result.willSkipSome, isTrue);
    });

    test('is blocked when there is no picture at all', () {
      final result = _rules.evaluate(BatchAction.exportPdf, <MediaItem>[
        _video,
      ]);

      expect(result.isAllowed, isFalse);
      expect(result.blockReason, BatchBlockReason.noSupportedItems);
    });

    test('willSkipSome is false when nothing is passed over', () {
      final result = _rules.evaluate(BatchAction.exportPdf, <MediaItem>[
        _photo,
        _gif,
      ]);

      expect(result.willSkipSome, isFalse);
    });
  });

  group('the selection size cap', () {
    test('a selection at the cap is allowed', () {
      final items = List<MediaItem>.generate(
        AppConstants.batchMaxSelectionSize,
        (i) => _item('m$i', MediaType.image),
      );

      expect(_rules.evaluate(BatchAction.addTags, items).isAllowed, isTrue);
    });

    test('one past the cap is refused, whatever the action', () {
      final items = List<MediaItem>.generate(
        AppConstants.batchMaxSelectionSize + 1,
        (i) => _item('m$i', MediaType.image),
      );

      for (final result in _rules.evaluateAll(items)) {
        expect(result.isAllowed, isFalse, reason: result.action.name);
        expect(result.blockReason, BatchBlockReason.selectionTooLarge);
      }
    });
  });

  group('applicableItems', () {
    test('keeps the order of the selection', () {
      final items = <MediaItem>[_gif, _video, _photo, _raw];

      expect(
        _rules.applicableItems(BatchAction.exportPdf, items).map((i) => i.id),
        <String>['gif', 'photo', 'raw'],
      );
    });

    test('is empty when nothing fits', () {
      expect(
        _rules.applicableItems(BatchAction.watermark, <MediaItem>[_video]),
        isEmpty,
      );
    });
  });

  group('needsConfirmation', () {
    test('is true for anything that writes a file or moves an original', () {
      for (final action in <BatchAction>[
        BatchAction.convert,
        BatchAction.watermark,
        BatchAction.exportPdf,
        BatchAction.moveToVault,
        BatchAction.moveToTrash,
      ]) {
        expect(_rules.needsConfirmation(action), isTrue, reason: action.name);
      }
    });

    test('is false for changes the user can simply undo', () {
      for (final action in <BatchAction>[
        BatchAction.addTags,
        BatchAction.removeTags,
        BatchAction.addToAlbum,
        BatchAction.favourite,
        BatchAction.unfavourite,
        BatchAction.transfer,
      ]) {
        expect(_rules.needsConfirmation(action), isFalse, reason: action.name);
      }
    });
  });

  group('evaluateAll', () {
    test('returns one verdict per action, in enum order', () {
      final results = _rules.evaluateAll(<MediaItem>[_photo]);

      expect(results, hasLength(BatchAction.values.length));
      expect(results.map((r) => r.action), BatchAction.values);
    });
  });
}
