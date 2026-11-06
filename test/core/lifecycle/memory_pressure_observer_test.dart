import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/lifecycle/memory_pressure_observer.dart';

class _RecordingImageCache extends ImageCache {
  int clears = 0;
  int liveClears = 0;

  @override
  void clear() {
    clears++;
    super.clear();
  }

  @override
  void clearLiveImages() {
    liveClears++;
    super.clearLiveImages();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('memory pressure clears the image cache and the app caches', () {
    final cache = _RecordingImageCache();
    var relieved = 0;
    final observer = MemoryPressureObserver(
      onPressure: () => relieved++,
      imageCache: () => cache,
    )..attach();
    addTearDown(observer.detach);

    WidgetsBinding.instance.handleMemoryPressure();

    expect(cache.clears, 1);
    expect(cache.liveClears, 1);
    expect(relieved, 1);
  });

  test('a detached observer does nothing', () {
    final cache = _RecordingImageCache();
    var relieved = 0;
    MemoryPressureObserver(
        onPressure: () => relieved++,
        imageCache: () => cache,
      )
      ..attach()
      ..detach();

    WidgetsBinding.instance.handleMemoryPressure();

    expect(relieved, 0);
  });
}
