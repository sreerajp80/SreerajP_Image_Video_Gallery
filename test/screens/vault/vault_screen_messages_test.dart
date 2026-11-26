import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/device/secure_window_service.dart';

/// Answers restore and delete with a fixed result, without a vault.
class _FakeBatchController extends VaultBatchController {
  final VaultBatchResult answer;

  _FakeBatchController(Ref ref, this.answer)
    : super(repository: _NoRepository(), ref: ref);

  @override
  Future<List<VaultItem>> findItemsWithMissingFolder(
    List<VaultItem> items,
  ) async => const <VaultItem>[];

  @override
  Future<void> restore(
    List<VaultItem> items, {
    String? fallbackFolderUri,
  }) async {
    state = AsyncValue<VaultBatchResult?>.data(answer);
  }

  @override
  Future<void> deleteForever(List<VaultItem> items) async {
    state = AsyncValue<VaultBatchResult?>.data(answer);
  }
}

class _NoRepository implements VaultRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoSecureWindow implements SecureWindowService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

VaultItem _item(String id) => VaultItem(
  id: id,
  originalPath: '/storage/emulated/0/DCIM/Camera/$id.jpg',
  originalFilename: '$id.jpg',
  encryptedFilename: '$id.enc',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  sizeBytes: 10,
  iv: 'aXY=',
  dateVaulted: DateTime(2026, 11, 2),
);

void main() {
  Future<void> run(
    WidgetTester tester, {
    required VaultBatchResult answer,
    required String button,
    required String confirm,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultItemsProvider.overrideWith(
            (ref) async => <VaultItem>[_item('a'), _item('b')],
          ),
          vaultThumbnailProvider.overrideWith((ref, id) async => null),
          vaultSettingsProvider.overrideWith(
            (ref) async => VaultSecuritySettings.defaults,
          ),
          secureWindowServiceProvider.overrideWithValue(_NoSecureWindow()),
          vaultBatchControllerProvider.overrideWith(
            (ref) => _FakeBatchController(ref, answer),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VaultScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(button));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, confirm));
    await tester.pumpAndSettle();
  }

  testWidgets('a restore says restored, not moved to the vault', (
    tester,
  ) async {
    await run(
      tester,
      answer: const VaultBatchResult(succeededIds: <String>['a']),
      button: 'Restore to gallery',
      confirm: 'Restore',
    );

    expect(find.text('1 item restored to the gallery'), findsOneWidget);
    expect(find.textContaining('moved to the vault'), findsNothing);
  });

  testWidgets('a restore that used the fallback folder says where', (
    tester,
  ) async {
    await run(
      tester,
      answer: const VaultBatchResult(
        succeededIds: <String>['a'],
        fallbackCount: 1,
      ),
      button: 'Restore to gallery',
      confirm: 'Restore',
    );

    expect(
      find.text(
        '1 item restored to the gallery 1 went to Pictures/Drishya Restored.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed restore says nothing could be restored', (
    tester,
  ) async {
    await run(
      tester,
      answer: const VaultBatchResult(failedCount: 1),
      button: 'Restore to gallery',
      confirm: 'Restore',
    );

    expect(find.text('Nothing could be restored'), findsOneWidget);
  });

  testWidgets('a delete says deleted for good', (tester) async {
    await run(
      tester,
      answer: const VaultBatchResult(succeededIds: <String>['a']),
      button: 'Delete for good',
      confirm: 'Delete for good',
    );

    expect(find.text('1 item deleted for good'), findsOneWidget);
  });
}
