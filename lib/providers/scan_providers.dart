import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/barcode_payload_parser.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/image_scan_service.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/intent_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/scan_action_resolver.dart';

/// Reads a payload and says what it is.
final barcodePayloadParserProvider = Provider<BarcodePayloadParser>((ref) {
  return const BarcodePayloadParser();
});

/// Decides which actions a code earns.
final scanActionResolverProvider = Provider<ScanActionResolver>((ref) {
  return const ScanActionResolver();
});

/// Hands a code to another app, within the permitted schemes.
final intentChannelProvider = Provider<IntentChannel>((ref) {
  return IntentChannel();
});

/// Reads codes out of a still picture, with no camera involved.
final imageScanServiceProvider = Provider<ImageScanService>((ref) {
  return ImageScanService(
    decoder: const MobileScannerImageDecoder(),
    parser: ref.watch(barcodePayloadParserProvider),
  );
});

/// Scans one picture and holds the result.
///
/// The scan is started by the screen rather than by watching a family
/// provider, because reading a picture takes real time and should happen when
/// the user asks for it, not when a widget rebuilds.
class ImageScanController extends StateNotifier<AsyncValue<ImageScanOutcome?>> {
  final Ref _ref;

  ImageScanController(this._ref) : super(const AsyncValue.data(null));

  /// Scans the picture at [path].
  Future<void> scan(String path) async {
    state = const AsyncValue.loading();

    // The service never throws: a failure comes back as an outcome, so the
    // screen can tell "no codes here" apart from "the reader would not run".
    final outcome = await _ref.read(imageScanServiceProvider).scanFile(path);
    state = AsyncValue.data(outcome);
  }

  /// Clears the result, so leaving and returning starts clean.
  void reset() => state = const AsyncValue.data(null);
}

final imageScanControllerProvider =
    StateNotifierProvider.autoDispose<
      ImageScanController,
      AsyncValue<ImageScanOutcome?>
    >((ref) {
      return ImageScanController(ref);
    });

/// The actions offered for one code.
final scanActionsProvider = Provider.family<List<ScanAction>, ScannedCode>((
  ref,
  code,
) {
  return ref.watch(scanActionResolverProvider).resolve(code);
});

/// Runs a chosen action.
///
/// Kept out of the widget so no screen builds an intent of its own. Returns
/// whether the Wi-Fi suggestion was taken, which is the one action whose
/// answer changes what the screen then says.
class ScanActionRunner {
  final IntentChannel _intents;

  const ScanActionRunner(this._intents);

  /// Copies text to the clipboard.
  Future<void> copy(String text, {bool isSensitive = false}) {
    return _intents.copyToClipboard(text, isSensitive: isSensitive);
  }

  /// Opens a URI, after the resolver has already approved its scheme.
  Future<void> open(String uri) => _intents.openUri(uri);

  /// Offers a network to Android and opens the Wi-Fi screen either way.
  ///
  /// The settings screen is opened whether or not the suggestion was taken,
  /// because the user still has to tap the network themselves. The app never
  /// joins a network on its own.
  Future<bool> connectWifi(WifiCredentials credentials) async {
    final accepted = await _intents.suggestWifiNetwork(credentials);
    await _intents.openWifiSettings();
    return accepted;
  }
}

final scanActionRunnerProvider = Provider<ScanActionRunner>((ref) {
  return ScanActionRunner(ref.watch(intentChannelProvider));
});
