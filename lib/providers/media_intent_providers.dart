import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/intent/media_intent_service.dart';

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
