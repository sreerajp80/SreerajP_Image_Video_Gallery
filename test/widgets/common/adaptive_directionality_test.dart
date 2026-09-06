import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// Reads the direction in force at the point the probe sits in the tree.
class _DirectionProbe extends StatelessWidget {
  final void Function(TextDirection direction) onBuild;

  const _DirectionProbe({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild(Directionality.of(context));
    return const SizedBox.shrink();
  }
}

void main() {
  /// Builds the wrapper under an ambient [ambient] direction and reports the
  /// direction the child ends up with.
  Future<TextDirection> directionFor(
    WidgetTester tester,
    String text, {
    TextDirection ambient = TextDirection.ltr,
    TextDirection? fallback,
  }) async {
    late TextDirection seen;

    await tester.pumpWidget(
      Directionality(
        textDirection: ambient,
        child: AdaptiveDirectionality(
          text: text,
          fallback: fallback,
          child: _DirectionProbe(onBuild: (direction) => seen = direction),
        ),
      ),
    );

    return seen;
  }

  group('AdaptiveDirectionality', () {
    testWidgets('lays Arabic text out right to left', (tester) async {
      expect(await directionFor(tester, 'مرحبا بالعالم'), TextDirection.rtl);
    });

    testWidgets('lays Malayalam text out left to right', (tester) async {
      expect(await directionFor(tester, 'മലയാളം കുറിപ്പ്'), TextDirection.ltr);
    });

    testWidgets('flips a right-to-left app for English text', (tester) async {
      expect(
        await directionFor(
          tester,
          'A holiday photo',
          ambient: TextDirection.rtl,
        ),
        TextDirection.ltr,
      );
    });

    testWidgets('keeps the ambient direction for neutral text', (tester) async {
      // A file name that is only digits must not flip the layout around it.
      expect(
        await directionFor(tester, '20260831', ambient: TextDirection.rtl),
        TextDirection.rtl,
      );
      expect(
        await directionFor(tester, '', ambient: TextDirection.ltr),
        TextDirection.ltr,
      );
    });

    testWidgets('uses the fallback for neutral text when given one', (
      tester,
    ) async {
      expect(
        await directionFor(
          tester,
          '1234',
          ambient: TextDirection.ltr,
          fallback: TextDirection.rtl,
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('the fallback never overrides real text', (tester) async {
      expect(
        await directionFor(
          tester,
          'photos',
          ambient: TextDirection.ltr,
          fallback: TextDirection.rtl,
        ),
        TextDirection.ltr,
      );
    });

    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveDirectionality(text: 'مرحبا', child: Text('مرحبا')),
        ),
      );

      expect(find.text('مرحبا'), findsOneWidget);
    });
  });
}
