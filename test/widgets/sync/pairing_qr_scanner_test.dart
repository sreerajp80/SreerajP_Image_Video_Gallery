import 'dart:async';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_scanner.dart';

void main() {
  group('QrFrameGate', () {
    test('the first accepted code wins and later frames are ignored', () async {
      final seen = <String>[];
      final gate = QrFrameGate(
        onCode: (raw) {
          seen.add(raw);
          return raw == 'ours';
        },
      );

      await gate.offer(() async => <String>['someone else', 'ours', 'after']);
      expect(seen, <String>['someone else', 'ours']);
      expect(gate.isDone, isTrue);

      var decoded = false;
      await gate.offer(() async {
        decoded = true;
        return <String>['ours'];
      });
      expect(decoded, isFalse);
    });

    test('a frame that arrives while one is decoding is dropped', () async {
      final gate = QrFrameGate(onCode: (_) => false);
      final slow = Completer<List<String>>();
      var second = false;

      final first = gate.offer(() => slow.future);
      await gate.offer(() async {
        second = true;
        return <String>[];
      });
      expect(second, isFalse);

      slow.complete(<String>[]);
      await first;
      await gate.offer(() async {
        second = true;
        return <String>[];
      });
      expect(second, isTrue);
    });

    test('a decoder failure skips the frame and keeps scanning', () async {
      final gate = QrFrameGate(onCode: (raw) => raw == 'ours');
      await gate.offer(() async => throw StateError('frame'));
      expect(gate.isDone, isFalse);
      await gate.offer(() async => <String>['ours']);
      expect(gate.isDone, isTrue);
    });
  });

  test('the scanner uses 720p by default so codes read from a distance', () {
    final scanner = PairingQrScanner(
      onCode: (_) => false,
      errorBuilder: (_) => const SizedBox(),
    );
    expect(scanner.resolution, ResolutionPreset.high);
  });

  Future<void> pumpScanner(
    WidgetTester tester,
    Future<List<CameraDescription>> Function() listCameras,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PairingQrScanner(
              onCode: (_) => false,
              listCameras: listCameras,
              errorBuilder: (_) => const Text('type the code'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a phone with no camera shows the error panel', (tester) async {
    await pumpScanner(tester, () async => const <CameraDescription>[]);
    expect(find.text('type the code'), findsOneWidget);
  });

  testWidgets('a camera that will not start shows the error panel', (
    tester,
  ) async {
    await pumpScanner(
      tester,
      () async => throw CameraException('denied', null),
    );
    expect(find.text('type the code'), findsOneWidget);
  });

  Future<void> pumpScannerStarting(
    WidgetTester tester,
    Future<List<CameraDescription>> Function() listCameras,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PairingQrScanner(
              onCode: (_) => false,
              listCameras: listCameras,
              errorBuilder: (_) => const Text('type the code'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void sendLifecycle(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets(
    'the permission dialog coming and going does not start a second camera',
    (tester) async {
      final pending = Completer<List<CameraDescription>>();
      var calls = 0;
      await pumpScannerStarting(tester, () {
        calls++;
        return pending.future;
      });
      expect(calls, 1);

      // What Android sends while the "Allow camera?" dialog is open.
      sendLifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pump();

      expect(calls, 1);
      expect(find.text('type the code'), findsNothing);

      pending.complete(const <CameraDescription>[]);
      await tester.pump();
    },
  );

  testWidgets(
    'leaving the app while the camera starts begins a fresh start on return',
    (tester) async {
      final first = Completer<List<CameraDescription>>();
      var calls = 0;
      await pumpScannerStarting(tester, () {
        calls++;
        if (calls == 1) return first.future;
        return Future<List<CameraDescription>>.error(
          CameraException('denied', null),
        );
      });

      sendLifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pump();
      expect(calls, 1);

      // The stale start ends. Its failure is ignored and a fresh start runs.
      first.completeError(CameraException('stale', null));
      await tester.pump();
      await tester.pump();

      expect(calls, 2);
      expect(find.text('type the code'), findsOneWidget);
    },
  );
}
