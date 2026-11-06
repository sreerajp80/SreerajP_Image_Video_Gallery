import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/playback_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/device/screen_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/exif_reader_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/frame_step_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/video/playback_speed_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/video/video_gesture_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/viewer/viewer_transform_service.dart';
import 'package:video_player/video_player.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Zoom, rotation, and dismiss maths for the image viewer.
final viewerTransformServiceProvider = Provider<ViewerTransformService>((ref) {
  return const ViewerTransformService();
});

/// The playback speed ladder.
final playbackSpeedServiceProvider = Provider<PlaybackSpeedService>((ref) {
  return const PlaybackSpeedService();
});

/// Drag-to-brightness, drag-to-volume, and drag-to-seek rules.
final videoGestureServiceProvider = Provider<VideoGestureService>((ref) {
  return const VideoGestureService();
});

/// Frame and skip stepping.
final frameStepServiceProvider = Provider<FrameStepService>((ref) {
  return const FrameStepService();
});

/// EXIF parsing.
final exifReaderServiceProvider = Provider<ExifReaderService>((ref) {
  return const ExifReaderService();
});

/// Screen brightness, media volume, and keep-awake.
final screenSettingsServiceProvider = Provider<ScreenSettingsService>((ref) {
  return PlatformScreenSettingsService();
});

/// Library changes the viewer makes to the item it shows.
///
/// The screen calls these rather than the repository, and each one refreshes
/// every list that could show the change.
class ViewerActions {
  final Ref _ref;

  ViewerActions(this._ref);

  /// Stars or un-stars an item.
  Future<void> toggleFavorite(String id) async {
    await _ref.read(mediaRepositoryProvider).toggleFavorite(id);
    // Reload the list so the star in the app bar and the grid agree.
    _ref.invalidate(mediaItemsProvider);
  }

  /// Moves an item to the trash. Nothing is deleted from the device.
  Future<void> moveToTrash(String id) => _setTrash(id, true);

  /// Takes an item back out of the trash (the snackbar's undo).
  Future<void> restoreFromTrash(String id) => _setTrash(id, false);

  Future<void> _setTrash(String id, bool trashed) async {
    await _ref.read(mediaRepositoryProvider).setTrash(id, trashed);
    _ref.read(trashRevisionProvider.notifier).state++;
    _ref.read(albumRevisionProvider.notifier).state++;
    _ref.invalidate(mediaItemsProvider);
  }
}

final viewerActionsProvider = Provider<ViewerActions>(ViewerActions.new);

/// Page the viewer is currently showing.
///
/// It is set when the viewer opens and updated as the user swipes, so the
/// details sheet and the app bar always describe the visible item.
final viewerPageIndexProvider = StateProvider<int>((ref) => 0);

/// Original bytes of one image, or null when they cannot be read.
///
/// Null is a normal answer, not a failure: the file may be missing, too large
/// for the memory cap, or a format we only have a thumbnail for. The viewer
/// falls back to the thumbnail in every one of those cases.
final fullImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, MediaItem>((ref, item) async {
      if (!item.isImage) return null;
      // Keep a decoded page around for a moment so paging back is instant.
      ref.keepAlive();
      return ref.watch(mediaRepositoryProvider).readOriginalBytes(item);
    });

/// EXIF metadata for one item, parsed once and then cached in the database.
///
/// Already indexed metadata is returned straight away. Otherwise the bytes are
/// read, parsed off the UI thread, and written back through the repository so
/// the next open costs nothing. Videos and unreadable files return null.
final mediaExifProvider = FutureProvider.autoDispose.family<ExifData?, MediaItem>((
  ref,
  item,
) async {
  if (item.exifData != null) return item.exifData;
  if (!item.isImage) return null;

  final repository = ref.watch(mediaRepositoryProvider);
  final bytes = await repository.readOriginalBytes(item);
  if (bytes == null) return null;

  final exif = await ref.watch(exifReaderServiceProvider).read(bytes);
  if (exif == null) return null;

  try {
    await repository.saveExif(item.id, exif);
  } catch (_) {
    // Safe to ignore: caching EXIF is an optimisation; the details sheet still
    // shows what was parsed.
  }
  return exif;
});

/// Drives one video clip and publishes an immutable [PlaybackState].
///
/// The widget layer never touches `video_player` directly: it reads the state
/// and calls the methods here, so all the awkward parts (initialisation
/// failures, the ticking listener, disposal) live in one place.
class VideoPlaybackController extends StateNotifier<PlaybackState> {
  final MediaItem _item;
  final PlaybackSpeedService _speedService;
  final FrameStepService _frameStepService;

  VideoPlayerController? _controller;
  bool _disposed = false;

  VideoPlaybackController({
    required MediaItem item,
    required PlaybackSpeedService speedService,
    required FrameStepService frameStepService,
  }) : _item = item,
       _speedService = speedService,
       _frameStepService = frameStepService,
       super(PlaybackState.initial);

  /// The platform controller, or null before it is ready.
  ///
  /// Only `VideoPlayer` needs this; everything else reads [state].
  VideoPlayerController? get controller => _controller;

  /// Loads the clip and starts playing it.
  ///
  /// A file that cannot be opened or decoded ends in an error state that the
  /// player draws as a message. It never throws at the widget.
  Future<void> initialize({bool autoPlay = true}) async {
    if (_controller != null) return;

    final uri = _item.uri;
    if (uri == null || uri.isEmpty) {
      state = state.copyWith(error: PlaybackError.unreadable);
      return;
    }

    try {
      final controller = VideoPlayerController.contentUri(Uri.parse(uri));
      _controller = controller;
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onControllerTick);
      state = state.copyWith(
        isInitialized: true,
        duration: controller.value.duration,
        volume: controller.value.volume,
        error: PlaybackError.none,
      );

      if (autoPlay) await controller.play();
    } catch (error) {
      AppLogger.warning('Video playback could not start', error: error);
      state = state.copyWith(error: PlaybackError.unsupportedFormat);
    }
  }

  /// Copies the platform player's values into our immutable state.
  void _onControllerTick() {
    final controller = _controller;
    if (_disposed || controller == null) return;

    final value = controller.value;
    state = state.copyWith(
      isInitialized: value.isInitialized,
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      isLooping: value.isLooping,
      position: value.position,
      duration: value.duration,
      speed: value.playbackSpeed,
      volume: value.volume,
      error: value.hasError ? PlaybackError.unreadable : PlaybackError.none,
    );
  }

  /// Plays if paused, pauses if playing.
  Future<void> togglePlay() async {
    final controller = _controller;
    if (controller == null || !state.isReady) return;

    if (state.isPlaying) {
      await controller.pause();
    } else {
      // Tapping play at the very end should restart rather than do nothing.
      if (state.position >= state.duration && state.duration > Duration.zero) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
  }

  /// Pauses playback, used when the page scrolls away or the app is hidden.
  Future<void> pause() async {
    final controller = _controller;
    if (controller == null || !state.isPlaying) return;
    await controller.pause();
  }

  /// Moves the playhead.
  Future<void> seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null || !state.isReady) return;
    await controller.seekTo(position);
    state = state.copyWith(position: position);
  }

  /// Steps one frame forward, pausing first so the frame stays on screen.
  Future<void> stepForward() async {
    if (!_frameStepService.canStep(state.duration)) return;
    await pause();
    await seekTo(
      _frameStepService.nextFrame(
        position: state.position,
        duration: state.duration,
      ),
    );
  }

  /// Steps one frame back, pausing first.
  Future<void> stepBackward() async {
    if (!_frameStepService.canStep(state.duration)) return;
    await pause();
    await seekTo(
      _frameStepService.previousFrame(
        position: state.position,
        duration: state.duration,
      ),
    );
  }

  /// Sets playback speed, snapped to the supported ladder.
  Future<void> setSpeed(double speed) async {
    final controller = _controller;
    if (controller == null || !state.isReady) return;
    final snapped = _speedService.nearest(speed);
    await controller.setPlaybackSpeed(snapped);
    state = state.copyWith(speed: snapped);
  }

  /// Turns repeat on or off.
  Future<void> toggleLooping() async {
    final controller = _controller;
    if (controller == null || !state.isReady) return;
    final next = !state.isLooping;
    await controller.setLooping(next);
    state = state.copyWith(isLooping: next);
  }

  /// Sets the clip volume between 0 and 1.
  Future<void> setVolume(double volume) async {
    final controller = _controller;
    if (controller == null || !state.isReady) return;
    final clamped = volume.isNaN ? 0.0 : volume.clamp(0.0, 1.0);
    await controller.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  @override
  void dispose() {
    _disposed = true;
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onControllerTick);
    controller?.dispose();
    super.dispose();
  }
}

/// One video controller per clip, thrown away when its page leaves the viewer.
final videoPlaybackControllerProvider = StateNotifierProvider.autoDispose
    .family<VideoPlaybackController, PlaybackState, MediaItem>((ref, item) {
      return VideoPlaybackController(
        item: item,
        speedService: ref.watch(playbackSpeedServiceProvider),
        frameStepService: ref.watch(frameStepServiceProvider),
      );
    });
