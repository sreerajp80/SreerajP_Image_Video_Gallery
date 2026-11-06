import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_flavor_config.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/core/lifecycle/memory_pressure_observer.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/memory_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/provider_retry.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/theme_provider.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/language_preference_store.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/safe_error_fallback.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/app_screen_protection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavorConfig.initialize();
  _installErrorHandlers();

  // Read the saved preferences before the first frame, so the app opens in the
  // theme and language the user chose instead of flashing the defaults and
  // then correcting itself.
  final AppSettings settings = await _loadSettings();

  runApp(
    ProviderScope(
      // Riverpod 3 retries a failing provider by default. This app was built
      // for "fail once, show the fallback" (hard rule 5): retrying a corrupt
      // photo or a refused permission only costs battery. See
      // docs/architecture.md section 8.
      retry: noProviderRetry,
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

/// Global error boundaries (engineering standard §11.1).
///
/// Handlers only log. The release-safe screen comes from
/// [ErrorWidget.builder], never from navigating inside a handler.
void _installErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (!kReleaseMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error('Uncaught async error', error: error, stackTrace: stack);
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        const SafeErrorFallback();
  }
}

/// Reads the stored preferences, falling back to the defaults.
///
/// Launch must not depend on this working. If the support directory cannot be
/// reached, the app opens with the default settings rather than not opening.
Future<AppSettings> _loadSettings() async {
  try {
    final directory = await getApplicationSupportDirectory();
    return await AppSettingsService(
      directory: directory,
      languageStore: SharedPreferencesLanguageStore(),
    ).load();
  } catch (error, stackTrace) {
    AppLogger.warning('Settings could not be loaded', error: error);
    AppLogger.debug(stackTrace.toString());
    return AppSettings.defaults;
  }
}

class GalleryApp extends ConsumerStatefulWidget {
  const GalleryApp({super.key});

  @override
  ConsumerState<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends ConsumerState<GalleryApp> {
  late final MemoryPressureObserver _memory;

  @override
  void initState() {
    super.initState();
    _memory = MemoryPressureObserver(onPressure: ref.read(memoryReliefProvider))
      ..attach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(mediaIntentControllerProvider)
          .start(onProblem: _showIntentProblem);
    });
  }

  /// Tells the user why a link from another app did not open.
  void _showIntentProblem(MediaIntentOutcome outcome) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final context = rootScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;
    final l10n = AppLocalizations.of(context)!;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == MediaIntentOutcome.refused
              ? l10n.errorOpenWithRefused
              : l10n.errorOpenWithFailed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _memory.detach();
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
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.titleApp,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: activeDarkTheme,
      themeMode: themeMode,
      // A null locale means "follow the phone", which is what the settings
      // screen calls System default.
      locale: locale,
      // Sanskrit fallbacks come first so they answer for `sa` (§8.3.1).
      localizationsDelegates: appLocalizationsDelegates,
      // qr_flutter, video_player and camera still import the SDK's frozen
      // Material. The bridge hands them the app's theme (for example the
      // video progress bar colours). They read no Material localizations,
      // so Sanskrit needs no extra delegate here (G22, architecture §21).
      // The bridge is deprecated on purpose: it is a temporary migration
      // tool. Remove it when those three packages move to material_ui.
      // AppScreenProtection applies the optional "Hide content" setting to
      // every screen (G28); the vault is protected on its own either way.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(
        child: AppScreenProtection(child: child ?? const SizedBox.shrink()),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      // A phone set to a language the app does not ship falls back to
      // English (engineering standard §8.4).
      localeResolutionCallback: (deviceLocale, supported) {
        for (final candidate in supported) {
          if (candidate.languageCode == deviceLocale?.languageCode) {
            return candidate;
          }
        }
        return const Locale('en');
      },
      routerConfig: appRouter,
    );
  }
}
