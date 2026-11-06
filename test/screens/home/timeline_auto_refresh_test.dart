import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/screens/timeline/timeline_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_permission_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import '../../helpers/locale_checks.dart';

class _FakeMediaRepository extends Fake implements MediaRepository {}

class _FakeMediaPermissionService extends Fake
    implements MediaPermissionService {}

/// Records scan calls instead of touching the device.
class _RecordingScanController extends MediaScanController {
  final List<bool> incrementalCalls = <bool>[];

  _RecordingScanController()
    : super(
        repository: _FakeMediaRepository(),
        permissionService: _FakeMediaPermissionService(),
      );

  @override
  Future<void> scan({bool incremental = false}) async {
    incrementalCalls.add(incremental);
  }
}

Widget _app(
  _RecordingScanController controller,
  MediaPermissionStatus permission, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      mediaPermissionStatusProvider.overrideWith((ref) async => permission),
      mediaScanControllerProvider.overrideWith((ref) => controller),
      timelineDataProvider.overrideWith(
        (ref) async => const TimelineData.empty(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _ShellLikeGate(),
    ),
  );
}

/// Builds the timeline only once permission has loaded, like the home shell.
class _ShellLikeGate extends ConsumerWidget {
  const _ShellLikeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(mediaPermissionStatusProvider).value;
    if (permission == null) return const SizedBox.shrink();
    return const TimelineScreen();
  }
}

void main() {
  testWidgets('opening the timeline with permission runs one quick scan', (
    tester,
  ) async {
    final controller = _RecordingScanController();

    await tester.pumpWidget(_app(controller, MediaPermissionStatus.granted));
    await tester.pumpAndSettle();

    expect(controller.incrementalCalls, <bool>[true]);
  });

  testWidgets('opening the timeline without permission does not scan', (
    tester,
  ) async {
    final controller = _RecordingScanController();

    await tester.pumpWidget(_app(controller, MediaPermissionStatus.denied));
    await tester.pumpAndSettle();

    expect(controller.incrementalCalls, isEmpty);
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets(
        'TimelineScreen (empty) renders cleanly in ${locale.languageCode}',
        (tester) async {
          await tester.pumpWidget(
            _app(
              _RecordingScanController(),
              MediaPermissionStatus.granted,
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();
          expectLocaleClean(tester, locale);
        },
      );
    }
  });
}
