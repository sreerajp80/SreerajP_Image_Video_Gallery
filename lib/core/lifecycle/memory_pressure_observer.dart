import 'package:flutter/widgets.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Frees memory when Android says the device is running low (engineering
/// standard §9.2, "Memory pressure: clear image cache").
///
/// It always empties Flutter's decoded-image cache. [onPressure] frees the
/// app's own caches, such as thumbnail bytes; nothing it holds is lost for
/// good, because every cache refills from disk on the next use.
class MemoryPressureObserver with WidgetsBindingObserver {
  final VoidCallback? onPressure;
  final ImageCache Function() _imageCache;

  MemoryPressureObserver({this.onPressure, ImageCache Function()? imageCache})
    : _imageCache = imageCache ?? (() => PaintingBinding.instance.imageCache);

  /// Starts listening. Call once, and [detach] when done.
  void attach() => WidgetsBinding.instance.addObserver(this);

  /// Stops listening.
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didHaveMemoryPressure() {
    final cache = _imageCache();
    cache.clear();
    cache.clearLiveImages();
    onPressure?.call();
    AppLogger.info('Memory pressure: image and thumbnail caches cleared');
  }
}
