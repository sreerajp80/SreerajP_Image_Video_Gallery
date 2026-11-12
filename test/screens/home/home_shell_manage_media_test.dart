import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media/delete_confirm_info.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/home/home_shell_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/media/fake_media_store_channel.dart';

void main() {
  testWidgets('no Manage media prompt over the Permission required screen', (
    tester,
  ) async {
    final channel = FakeMediaStoreChannel()
      ..deleteInfo = const DeleteConfirmInfo(
        systemConfirmsDelete: true,
        manageMediaSupported: true,
        manageMediaGranted: false,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaStoreChannelProvider.overrideWithValue(channel),
          mediaPermissionStatusProvider.overrideWith(
            (ref) async => MediaPermissionStatus.denied,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Allow Manage media?'), findsNothing);
  });
}
