import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_session_body.dart';
import 'package:material_ui/material_ui.dart';

/// The body only reads the session to pass it to the send picker. The done
/// and failed phases never touch it.
class _UnusedSession implements TransferSessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

Future<void> _pump(WidgetTester tester, TransferSessionState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transferSessionProvider.overrideWithValue(_UnusedSession())],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransferSessionBody(
            state: state,
            endActions: [
              FilledButton(onPressed: () {}, child: const Text('again')),
              TextButton(onPressed: () {}, child: const Text('close')),
            ],
          ),
        ),
      ),
    ),
  );
  // One frame: the live phases draw a spinner that never settles.
  await tester.pump();
}

void main() {
  testWidgets('a finished transfer offers the end buttons', (tester) async {
    await _pump(
      tester,
      const TransferSessionState(
        phase: SyncPhase.done,
        role: SyncRole.receive,
        totals: TransferOutcome(skippedCount: 1),
      ),
    );
    expect(find.text('again'), findsOneWidget);
    expect(find.text('close'), findsOneWidget);
  });

  testWidgets('a failed transfer offers the end buttons', (tester) async {
    await _pump(
      tester,
      const TransferSessionState(
        phase: SyncPhase.failed,
        failure: TransferFailure.connectionLost,
      ),
    );
    expect(find.text('again'), findsOneWidget);
    expect(find.text('close'), findsOneWidget);
  });

  testWidgets('a live transfer does not show them', (tester) async {
    await _pump(tester, const TransferSessionState(phase: SyncPhase.paired));
    expect(find.text('again'), findsNothing);
  });
}
