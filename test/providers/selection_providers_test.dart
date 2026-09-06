import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  SelectionNotifier notifier() => container.read(selectionProvider.notifier);
  Set<String> selection() => container.read(selectionProvider);

  group('toggle', () {
    test('ticks an item that was not ticked', () {
      notifier().toggle('a');
      expect(selection(), <String>{'a'});
    });

    test('unticks an item that was', () {
      notifier()
        ..toggle('a')
        ..toggle('a');
      expect(selection(), isEmpty);
    });

    test('keeps several items independently', () {
      notifier()
        ..toggle('a')
        ..toggle('b')
        ..toggle('c')
        ..toggle('b');

      expect(selection(), <String>{'a', 'c'});
    });

    test('emits a new set rather than mutating the old one', () {
      // The grids rebuild off identity. Mutating the set in place would mean
      // a tick that never reached the screen.
      notifier().toggle('a');
      final first = selection();

      notifier().toggle('b');
      expect(identical(first, selection()), isFalse);
      expect(first, <String>{'a'});
    });
  });

  group('selectionMode and count', () {
    test('mode follows whether anything is ticked', () {
      expect(container.read(selectionModeProvider), isFalse);

      notifier().toggle('a');
      expect(container.read(selectionModeProvider), isTrue);

      notifier().toggle('a');
      expect(container.read(selectionModeProvider), isFalse);
    });

    test('count matches the selection', () {
      notifier()
        ..toggle('a')
        ..toggle('b');
      expect(container.read(selectionCountProvider), 2);
    });
  });

  group('selectAll', () {
    test('ticks everything given', () {
      notifier().selectAll(<String>['a', 'b', 'c']);
      expect(selection(), <String>{'a', 'b', 'c'});
    });

    test('adds to what is already ticked', () {
      notifier()
        ..toggle('z')
        ..selectAll(<String>['a', 'b']);

      expect(selection(), <String>{'z', 'a', 'b'});
    });

    test('does not duplicate an item already ticked', () {
      notifier()
        ..toggle('a')
        ..selectAll(<String>['a', 'b']);

      expect(selection(), hasLength(2));
    });

    test('stops at the cap', () {
      notifier().selectAll(
        List<String>.generate(
          AppConstants.batchMaxSelectionSize + 50,
          (i) => 'm$i',
        ),
      );

      expect(selection(), hasLength(AppConstants.batchMaxSelectionSize));
    });
  });

  group('the selection cap', () {
    test('refuses one more past the cap rather than growing', () {
      // Stopping at the boundary is kinder than letting someone select six
      // hundred photos and only then being told the batch will not take them.
      final ids = List<String>.generate(
        AppConstants.batchMaxSelectionSize,
        (i) => 'm$i',
      );
      notifier().selectAll(ids);

      expect(notifier().isFull, isTrue);
      notifier().toggle('one_too_many');

      expect(selection(), hasLength(AppConstants.batchMaxSelectionSize));
      expect(selection().contains('one_too_many'), isFalse);
    });

    test('still allows unticking when full', () {
      final ids = List<String>.generate(
        AppConstants.batchMaxSelectionSize,
        (i) => 'm$i',
      );
      notifier().selectAll(ids);

      notifier().toggle('m0');
      expect(selection(), hasLength(AppConstants.batchMaxSelectionSize - 1));
      expect(notifier().isFull, isFalse);
    });
  });

  group('clear', () {
    test('unticks everything', () {
      notifier()
        ..selectAll(<String>['a', 'b', 'c'])
        ..clear();

      expect(selection(), isEmpty);
      expect(container.read(selectionModeProvider), isFalse);
    });

    test('is harmless when nothing is ticked', () {
      notifier().clear();
      expect(selection(), isEmpty);
    });
  });

  group('retainOnly', () {
    test('drops ids that are no longer in the library', () {
      // Called after a batch that moved photos into the vault or the trash,
      // so the selection cannot keep pointing at rows that have gone.
      notifier().selectAll(<String>['a', 'b', 'c']);
      notifier().retainOnly(<String>{'a', 'c', 'unrelated'});

      expect(selection(), <String>{'a', 'c'});
    });

    test('leaves the selection alone when nothing was dropped', () {
      notifier().selectAll(<String>['a', 'b']);
      final before = selection();

      notifier().retainOnly(<String>{'a', 'b', 'c'});
      expect(identical(before, selection()), isTrue);
    });

    test('can empty the selection entirely', () {
      notifier().selectAll(<String>['a', 'b']);
      notifier().retainOnly(<String>{});

      expect(selection(), isEmpty);
    });
  });

  group('contains', () {
    test('reports what is ticked', () {
      notifier().toggle('a');

      expect(notifier().contains('a'), isTrue);
      expect(notifier().contains('b'), isFalse);
    });
  });

  group('isActive', () {
    test('is false until something is ticked', () {
      expect(notifier().isActive, isFalse);
      notifier().toggle('a');
      expect(notifier().isActive, isTrue);
    });
  });
}
