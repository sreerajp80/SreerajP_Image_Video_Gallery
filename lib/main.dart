import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_flavor_config.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/theme_provider.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/services/intent/media_intent_service.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavorConfig.initialize();

  // Read the saved preferences before the first frame, so the app opens in the
  // theme and language the user chose instead of flashing the defaults and
  // then correcting itself.
  final AppSettings settings = await _loadSettings();

  runApp(
    ProviderScope(
      overrides: <Override>[
        appSettingsProvider.overrideWith(
          (ref) => AppSettingsNotifier(
            service: () => ref.read(appSettingsServiceProvider.future),
            initial: settings,
          ),
        ),
      ],
      child: const GalleryApp(),
    ),
  );
}

/// Reads the stored preferences, falling back to the defaults.
///
/// Launch must not depend on this working. If the support directory cannot be
/// reached, the app opens with the default settings rather than not opening.
Future<AppSettings> _loadSettings() async {
  try {
    final directory = await getApplicationSupportDirectory();
    return await AppSettingsService(directory: directory).load();
  } catch (_) {
    return AppSettings.defaults;
  }
}

class GalleryApp extends ConsumerStatefulWidget {
  const GalleryApp({super.key});

  @override
  ConsumerState<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends ConsumerState<GalleryApp> {
  StreamSubscription<MediaIntentData>? _intentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMediaIntents();
    });
  }

  Future<void> _initMediaIntents() async {
    final intentService = ref.read(mediaIntentServiceProvider);
    final repository = ref.read(mediaRepositoryProvider);

    // Check if the app was opened via an external image/video intent
    final initial = await intentService.getInitialMediaIntent();
    if (initial != null) {
      await _openIntentMedia(initial, repository);
    }

    // Listen for media intents arriving while the app is already running
    _intentSubscription = intentService.incomingIntents.listen((data) {
      _openIntentMedia(data, repository);
    });
  }

  Future<void> _openIntentMedia(
    MediaIntentData data,
    dynamic repository,
  ) async {
    try {
      final item = await ref
          .read(mediaIntentServiceProvider)
          .resolveMediaItem(data, repository);
      ref.read(externalMediaRegistryProvider.notifier).register(item);
      appRouter.push(mediaViewerPath(item.id));
    } catch (_) {}
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final ThemeData activeDarkTheme = themePreference == ThemePreference.amoled
        ? AppTheme.amoledTheme
        : AppTheme.darkTheme;

    ThemeMode themeMode;
    switch (themePreference) {
      case ThemePreference.light:
        themeMode = ThemeMode.light;
        break;
      case ThemePreference.dark:
      case ThemePreference.amoled:
        themeMode = ThemeMode.dark;
        break;
      case ThemePreference.system:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'SreerajP Image Video Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: activeDarkTheme,
      themeMode: themeMode,
      // A null locale means "follow the phone", which is what the settings
      // screen calls System default.
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
