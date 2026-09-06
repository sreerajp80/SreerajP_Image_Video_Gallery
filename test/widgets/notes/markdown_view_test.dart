import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/widgets/notes/markdown_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('rendering', () {
    testWidgets('an empty note shows the empty state', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarkdownView(source: '', emptyState: Text('nothing here'))),
      );

      expect(find.text('nothing here'), findsOneWidget);
    });

    testWidgets('a paragraph is shown', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarkdownView(source: 'Taken at Kovalam.')),
      );

      expect(find.textContaining('Taken at Kovalam.'), findsOneWidget);
    });

    testWidgets('headings, lists and quotes all render', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MarkdownView(
            source: '# Trip\n\n- rice\n\n1. first\n\n> quoted\n\n---',
          ),
        ),
      );

      expect(find.textContaining('Trip'), findsOneWidget);
      expect(find.textContaining('rice'), findsOneWidget);
      expect(find.textContaining('first'), findsOneWidget);
      expect(find.textContaining('quoted'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('a task item shows a tick box in each state', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarkdownView(source: '- [x] done\n- [ ] to do')),
      );

      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('a fenced block keeps its text', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarkdownView(source: '```\nkeep **this**\n```')),
      );

      expect(find.textContaining('keep **this**'), findsOneWidget);
    });

    testWidgets('malayalam text renders', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarkdownView(source: '# കോവളം\n\nകടപ്പുറം')),
      );

      expect(find.textContaining('കോവളം'), findsOneWidget);
    });

    testWidgets('half-typed markdown does not throw', (tester) async {
      for (final source in <String>['**', '[x](', '```', '- [', '#']) {
        await tester.pumpWidget(_wrap(MarkdownView(source: source)));
        expect(tester.takeException(), isNull, reason: source);
      }
    });
  });

  group('links', () {
    testWidgets('an https link is tappable and reports its target', (
      tester,
    ) async {
      String? opened;

      await tester.pumpWidget(
        _wrap(
          MarkdownView(
            source: '[the map](https://example.com/map)',
            onOpenLink: (target) => opened = target,
          ),
        ),
      );

      await tester.tap(find.textContaining('the map'));
      await tester.pump();

      expect(opened, 'https://example.com/map');
    });

    // A note can hold text pasted in from a scanned code, so a link in one is
    // no more trusted than a link on a poster.
    testWidgets('a dangerous link is never opened', (tester) async {
      for (final target in <String>[
        'javascript:alert(1)',
        'file:///etc/passwd',
        'content://media/external/images/1',
        'intent://scan#Intent;end',
      ]) {
        String? opened;
        var blocked = false;

        await tester.pumpWidget(
          _wrap(
            MarkdownView(
              source: '[tap me]($target)',
              onOpenLink: (value) => opened = value,
              onBlockedLink: () => blocked = true,
            ),
          ),
        );

        await tester.tap(find.textContaining('tap me'));
        await tester.pump();

        expect(opened, isNull, reason: target);
        expect(blocked, isTrue, reason: target);
      }
    });

    testWidgets('a tel link is allowed', (tester) async {
      String? opened;

      await tester.pumpWidget(
        _wrap(
          MarkdownView(
            source: '[call](tel:+919876543210)',
            onOpenLink: (target) => opened = target,
          ),
        ),
      );

      await tester.tap(find.textContaining('call'));
      await tester.pump();

      expect(opened, 'tel:+919876543210');
    });
  });

  group('the scheme rule itself', () {
    test('permitted schemes pass', () {
      for (final target in <String>[
        'https://example.com',
        'http://example.com',
        'tel:+911234567',
        'mailto:a@example.com',
        'sms:+911234567',
        'geo:8.5,76.9',
        'example.com',
      ]) {
        expect(MarkdownView.isOpenableLink(target), isTrue, reason: target);
      }
    });

    test('everything else is refused', () {
      for (final target in <String>[
        '',
        '   ',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'content://x',
        'intent://x',
        'ftp://example.com',
        'data:text/html,x',
      ]) {
        expect(MarkdownView.isOpenableLink(target), isFalse, reason: target);
      }
    });
  });
}
