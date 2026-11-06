import 'dart:async';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';

/// Lets one camera frame at a time through to the decoder, and stops for
/// good once a code is accepted.
///
/// Frames that arrive while one is still being decoded are dropped, so a
/// slow phone checks fewer frames rather than piling them up.
class QrFrameGate {
  /// Asked about each code found. Returns true to accept it and stop.
  final bool Function(String raw) onCode;

  bool _busy = false;
  bool _done = false;

  QrFrameGate({required this.onCode});

  /// True once a code has been accepted.
  bool get isDone => _done;

  /// Decodes one frame with [decode], unless one is already in flight or a
  /// code was already accepted. A decoder failure skips the frame.
  Future<void> offer(Future<List<String>> Function() decode) async {
    if (_busy || _done) return;
    _busy = true;
    try {
      for (final raw in await decode()) {
        if (_done) return;
        if (raw.isNotEmpty && onCode(raw)) {
          _done = true;
          return;
        }
      }
    } catch (error) {
      // One frame the reader could not take. The next frame is tried.
      AppLogger.debug('A pairing camera frame could not be decoded');
    } finally {
      _busy = false;
    }
  }
}

/// The live camera that reads the other phone's pairing QR code.
///
/// The preview comes from the official `camera` plugin (CameraX on
/// Android); each frame's brightness plane goes to the ZXing reader in
/// Kotlin. The camera is released when the app leaves the foreground and
/// when this widget goes away, for example when the user switches to typing
/// the code.
class PairingQrScanner extends ConsumerStatefulWidget {
  /// Asked about each code found. Returns true when the code is a pairing
  /// code the screen accepted; the camera then stops.
  final bool Function(String raw) onCode;

  /// Shown when there is no camera, or it will not start (for example the
  /// permission was refused).
  final WidgetBuilder errorBuilder;

  /// Lists the cameras. Replaced in tests.
  final Future<List<CameraDescription>> Function() listCameras;

  const PairingQrScanner({
    super.key,
    required this.onCode,
    required this.errorBuilder,
    this.listCameras = availableCameras,
  });

  @override
  ConsumerState<PairingQrScanner> createState() => _PairingQrScannerState();
}

class _PairingQrScannerState extends ConsumerState<PairingQrScanner>
    with WidgetsBindingObserver {
  late final QrFrameGate _gate = QrFrameGate(onCode: _accept);
  CameraController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_release(rebuild: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_release());
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        !_gate.isDone &&
        !_failed) {
      unawaited(_start());
    }
  }

  bool _accept(String raw) {
    final accepted = widget.onCode(raw);
    if (accepted) unawaited(_release());
    return accepted;
  }

  Future<void> _start() async {
    try {
      final cameras = await widget.listCameras();
      if (cameras.isEmpty) {
        _fail();
        return;
      }
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        // Pairing never records sound; RECORD_AUDIO is removed from the
        // manifest.
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted || _gate.isDone) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      setState(() => _controller = controller);
    } catch (error) {
      AppLogger.warning('Starting the pairing camera failed', error: error);
      _fail();
    }
  }

  void _fail() {
    if (mounted) setState(() => _failed = true);
  }

  void _onFrame(CameraImage image) {
    if (image.planes.isEmpty) return;
    final luminance = image.planes.first;
    final channel = ref.read(barcodeChannelProvider);
    unawaited(
      _gate.offer(
        () => channel.decodeLuminance(
          bytes: luminance.bytes,
          width: image.width,
          height: image.height,
          rowStride: luminance.bytesPerRow,
        ),
      ),
    );
  }

  /// Stops and frees the camera. The preview is taken off the screen first,
  /// so a disposed controller is never drawn.
  Future<void> _release({bool rebuild = true}) async {
    final controller = _controller;
    if (controller == null) return;
    if (rebuild && mounted) {
      setState(() => _controller = null);
    } else {
      _controller = null;
    }
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (error) {
      AppLogger.debug('Stopping the pairing camera stream failed');
    }
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.errorBuilder(context);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
