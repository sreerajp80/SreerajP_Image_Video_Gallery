import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/intent/media_intent_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provides the single instance of [MediaIntentService].
final mediaIntentServiceProvider = Provider<MediaIntentService>((ref) {
  final service = MediaIntentService();
  ref.onDispose(service.dispose);
  return service;
});

/// Holds transient [MediaItem] instances opened from external intents.
final externalMediaRegistryProvider =
    StateNotifierProvider<ExternalMediaRegistry, Map<String, MediaItem>>((ref) {
      return ExternalMediaRegistry();
    });

/// State notifier managing in-memory items opened from other apps.
class ExternalMediaRegistry extends StateNotifier<Map<String, MediaItem>> {
  ExternalMediaRegistry() : super(const <String, MediaItem>{});

  /// Registers an external item so screens can look it up by id.
  void register(MediaItem item) {
    state = <String, MediaItem>{...state, item.id: item};
  }
}

/// Looks up an external media item by id, or null if not registered.
final externalMediaItemProvider = Provider.family<MediaItem?, String>((
  ref,
  id,
) {
  final registry = ref.watch(externalMediaRegistryProvider);
  return registry[id];
});

/// What happened to one "open with" link from another app.
enum MediaIntentOutcome {
  /// The viewer opened it.
  opened,

  /// Android refused it before it reached the app (for example a link into
  /// this app's private files).
  refused,

  /// It was allowed but could not be opened (gone, unreadable).
  failed,
}

/// Opens links that other apps hand over with "open with".
///
/// It reads the launch link once, then listens for links that arrive while
/// the app runs. A refused or failed link is reported through [onProblem], so
/// the screen can tell the user why nothing opened (standard §11.2).
class MediaIntentController {
  final MediaIntentService _service;
  final MediaRepository _repository;
  final ExternalMediaRegistry _registry;
  final void Function(String location) _open;

  StreamSubscription<MediaIntentData>? _subscription;

  MediaIntentController({
    required MediaIntentService service,
    required MediaRepository repository,
    required ExternalMediaRegistry registry,
    required void Function(String location) open,
  }) : _service = service,
       _repository = repository,
       _registry = registry,
       _open = open;

  /// Handles the launch link, then every later one. Call once.
  Future<void> start({
    required void Function(MediaIntentOutcome outcome) onProblem,
  }) async {
    Future<void> handleAndReport(MediaIntentData data) async {
      final outcome = await handle(data);
      if (outcome != MediaIntentOutcome.opened) onProblem(outcome);
    }

    final initial = await _service.getInitialMediaIntent();
    if (initial != null) await handleAndReport(initial);
    _subscription = _service.incomingIntents.listen(handleAndReport);
  }

  /// Opens one link and says what happened.
  Future<MediaIntentOutcome> handle(MediaIntentData data) async {
    if (data.refused) {
      AppLogger.info('A shared link was refused by the link rules');
      return MediaIntentOutcome.refused;
    }
    try {
      final item = await _service.resolveMediaItem(data, _repository);
      _registry.register(item);
      _open(mediaViewerPath(item.id));
      return MediaIntentOutcome.opened;
    } catch (error, stackTrace) {
      // A file another app handed over may be gone or unreadable. The app
      // stays where it is and the user is told.
      AppLogger.error(
        'Opening shared media failed',
        error: error,
        stackTrace: stackTrace,
      );
      return MediaIntentOutcome.failed;
    }
  }

  /// Stops listening.
  void dispose() => _subscription?.cancel();
}

/// The single [MediaIntentController], which opens the viewer through the
/// app router.
final mediaIntentControllerProvider = Provider<MediaIntentController>((ref) {
  final controller = MediaIntentController(
    service: ref.watch(mediaIntentServiceProvider),
    repository: ref.watch(mediaRepositoryProvider),
    registry: ref.watch(externalMediaRegistryProvider.notifier),
    open: (location) => appRouter.push(location),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
