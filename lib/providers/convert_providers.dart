import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_result.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/size_estimate.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/compression_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/image_codec_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/image_resize_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_layout_service.dart';

/// Pure resize maths.
final imageResizeServiceProvider = Provider<ImageResizeService>((ref) {
  return const ImageResizeService();
});

/// Naming and atomic writing for every file this phase produces.
final outputNamingServiceProvider = Provider<OutputNamingService>((ref) {
  return const OutputNamingService();
});

/// The native WEBP encoder.
final imageCodecChannelProvider = Provider<ImageCodecChannel>((ref) {
  return ImageCodecChannel();
});

/// Decode, resize, and re-encode.
final formatConversionServiceProvider = Provider<FormatConversionService>((
  ref,
) {
  return FormatConversionService(
    resizeService: ref.watch(imageResizeServiceProvider),
    codecChannel: ref.watch(imageCodecChannelProvider),
  );
});

/// The real-encode size preview.
final compressionServiceProvider = Provider<CompressionService>((ref) {
  return CompressionService(
    conversionService: ref.watch(formatConversionServiceProvider),
  );
});

/// Pure PDF page maths.
final pdfLayoutServiceProvider = Provider<PdfLayoutService>((ref) {
  return const PdfLayoutService();
});

/// The PDF document builder.
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService(
    conversionService: ref.watch(formatConversionServiceProvider),
    layoutService: ref.watch(pdfLayoutServiceProvider),
    namingService: ref.watch(outputNamingServiceProvider),
  );
});

/// Holds what the converter screen is currently set to.
///
/// The screen never edits a request itself; every control calls one of these
/// methods, so the rules about ranges live in one place.
class ConversionRequestNotifier extends StateNotifier<ConversionRequest> {
  ConversionRequestNotifier({required ImageOutputFormat initialFormat})
    : super(ConversionRequest(format: initialFormat));

  void setFormat(ImageOutputFormat format) {
    state = state.copyWith(format: format);
  }

  void setQuality(int quality) {
    state = state.copyWith(
      quality: quality.clamp(
        AppConstants.convertMinQuality,
        AppConstants.convertMaxQuality,
      ),
    );
  }

  void setStripMetadata(bool strip) {
    state = state.copyWith(stripMetadata: strip);
  }

  void setResizeMode(ResizeMode mode) {
    state = state.copyWith(resize: state.resize.copyWith(mode: mode));
  }

  void setLongestSide(int pixels) {
    state = state.copyWith(
      resize: state.resize.copyWith(
        longestSide: pixels.clamp(
          AppConstants.convertMinLongestSide,
          AppConstants.convertMaxLongestSide,
        ),
      ),
    );
  }

  void setExactSize({int? width, int? height}) {
    state = state.copyWith(
      resize: state.resize.copyWith(
        width: width?.clamp(1, AppConstants.convertMaxLongestSide),
        height: height?.clamp(1, AppConstants.convertMaxLongestSide),
      ),
    );
  }

  void setPercent(int percent) {
    state = state.copyWith(
      resize: state.resize.copyWith(
        percent: percent.clamp(
          AppConstants.convertMinPercent,
          AppConstants.convertMaxPercent,
        ),
      ),
    );
  }

  void setKeepAspect(bool keep) {
    state = state.copyWith(resize: state.resize.copyWith(keepAspect: keep));
  }
}

/// The conversion settings for one photo.
///
/// The format starts on whatever the file already is, so the screen opens on
/// a setting that changes nothing until the user asks for something else.
final conversionRequestProvider = StateNotifierProvider.autoDispose
    .family<ConversionRequestNotifier, ConversionRequest, MediaItem>((
      ref,
      item,
    ) {
      return ConversionRequestNotifier(
        initialFormat: ImageOutputFormat.forFileName(item.displayName),
      );
    });

/// The original bytes of the photo being converted, or null when unavailable.
///
/// Null covers a missing file, an unreadable one, and a file too big to
/// decode safely. The screen shows a message for all three.
final convertSourceBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, MediaItem>((ref, item) async {
      if (!item.isImage) return null;
      if (!const OutputNamingService().isConvertibleSize(item.size)) {
        return null;
      }

      // Every size preview re-encodes these same bytes, so they are worth
      // keeping while the screen is open.
      ref.keepAlive();
      return ref
          .watch(mediaRepositoryProvider)
          .readOriginalBytes(
            item,
            maxBytes: AppConstants.convertMaxSourceBytes,
          );
    });

/// Everything one size preview needs, as a single comparable key.
@immutable
class EstimateRequest {
  final MediaItem item;
  final ConversionRequest request;

  const EstimateRequest({required this.item, required this.request});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateRequest &&
          runtimeType == other.runtimeType &&
          item.id == other.item.id &&
          request == other.request;

  @override
  int get hashCode => Object.hash(item.id, request);
}

/// How big the converted copy would be, at the settings on screen.
///
/// The picture really is encoded, so the number is exact. The work waits a
/// moment after the last change, so dragging a slider does not queue one
/// encode per pixel of finger movement. A failure resolves to null and the
/// screen simply shows no estimate.
final conversionEstimateProvider = FutureProvider.autoDispose
    .family<SizeEstimate?, EstimateRequest>((ref, key) async {
      // Set when a newer setting replaces this one, so the wait below can
      // bail out instead of paying for an encode nobody will see.
      var superseded = false;
      ref.onDispose(() => superseded = true);

      final bytes = await ref.watch(
        convertSourceBytesProvider(key.item).future,
      );
      if (bytes == null) return null;

      await Future<void>.delayed(
        const Duration(milliseconds: AppConstants.convertEstimateDebounceMs),
      );
      if (superseded) return null;

      try {
        return await ref
            .watch(compressionServiceProvider)
            .estimate(
              sourceBytes: bytes,
              request: key.request,
              originalBytes: key.item.size,
            );
      } catch (_) {
        // A file the decoder cannot read, or a device with no WEBP encoder.
        // The screen already copes with a missing estimate.
        return null;
      }
    });

/// The state of a conversion the user asked to save.
///
/// `null` data means nothing has been saved yet; a value means the last save
/// finished and says where the copy went.
class ConvertSaveController
    extends StateNotifier<AsyncValue<ConversionResult?>> {
  final FormatConversionService _conversionService;
  final OutputNamingService _namingService;

  ConvertSaveController({
    required FormatConversionService conversionService,
    required OutputNamingService namingService,
  }) : _conversionService = conversionService,
       _namingService = namingService,
       super(const AsyncValue<ConversionResult?>.data(null));

  /// Converts at full resolution and writes the result as a new file.
  ///
  /// The original is only read. Any failure is reported through the state,
  /// never thrown at the widget.
  Future<void> save({
    required MediaItem item,
    required ConversionRequest request,
    required Uint8List sourceBytes,
  }) async {
    state = const AsyncValue<ConversionResult?>.loading();
    try {
      final encoded = await _conversionService.convert(
        sourceBytes: sourceBytes,
        request: request,
      );

      final File file = await _namingService.saveBytes(
        sourcePath: item.path,
        suffix: AppConstants.convertOutputSuffix,
        extension: request.format.extension,
        bytes: encoded.bytes,
      );

      state = AsyncValue<ConversionResult?>.data(
        ConversionResult(
          path: file.path,
          bytes: encoded.bytes.length,
          width: encoded.width,
          height: encoded.height,
          originalBytes: item.size,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue<ConversionResult?>.error(error, stackTrace);
    }
  }

  /// Clears the result so the screen stops showing the last message.
  void clear() => state = const AsyncValue<ConversionResult?>.data(null);
}

/// Controller the converter's save button talks to.
final convertSaveControllerProvider =
    StateNotifierProvider.autoDispose<
      ConvertSaveController,
      AsyncValue<ConversionResult?>
    >((ref) {
      return ConvertSaveController(
        conversionService: ref.watch(formatConversionServiceProvider),
        namingService: ref.watch(outputNamingServiceProvider),
      );
    });

/// The page settings on the PDF export screen.
final pdfExportOptionsProvider = StateProvider.autoDispose<PdfExportOptions>((
  ref,
) {
  return const PdfExportOptions();
});

/// The photos picked for the PDF, in the order they were picked.
///
/// Order matters: it is the page order of the finished document, so a plain
/// set would not do.
class PdfSelectionNotifier extends StateNotifier<List<String>> {
  PdfSelectionNotifier() : super(const <String>[]);

  bool contains(String id) => state.contains(id);

  /// Adds a photo, or removes it when it is already picked.
  void toggle(String id) {
    if (state.contains(id)) {
      state = state.where((value) => value != id).toList(growable: false);
      return;
    }
    if (state.length >= AppConstants.pdfMaxPages) return;
    state = <String>[...state, id];
  }

  void clear() => state = const <String>[];
}

/// Which photos the PDF export screen has picked.
final pdfSelectionProvider =
    StateNotifierProvider.autoDispose<PdfSelectionNotifier, List<String>>((
      ref,
    ) {
      return PdfSelectionNotifier();
    });

/// How far along a PDF export is.
@immutable
class PdfExportProgress {
  /// How many photos have been prepared so far.
  final int done;

  /// How many photos will be prepared in total.
  final int total;

  const PdfExportProgress({required this.done, required this.total});

  /// Share of the work finished, 0 to 1.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfExportProgress &&
          runtimeType == other.runtimeType &&
          done == other.done &&
          total == other.total;

  @override
  int get hashCode => Object.hash(done, total);
}

/// Progress of the PDF export currently running, or null when none is.
final pdfExportProgressProvider = StateProvider.autoDispose<PdfExportProgress?>(
  (ref) => null,
);

/// The state of a PDF export the user asked for.
class PdfExportController extends StateNotifier<AsyncValue<PdfExportResult?>> {
  final PdfExportService _exportService;
  final void Function(PdfExportProgress?) _reportProgress;

  PdfExportController({
    required PdfExportService exportService,
    required void Function(PdfExportProgress?) reportProgress,
  }) : _exportService = exportService,
       _reportProgress = reportProgress,
       super(const AsyncValue<PdfExportResult?>.data(null));

  /// Builds the document from [imagePaths] and writes it beside the first.
  Future<void> export({
    required List<String> imagePaths,
    required PdfExportOptions options,
  }) async {
    state = const AsyncValue<PdfExportResult?>.loading();
    _reportProgress(PdfExportProgress(done: 0, total: imagePaths.length));

    try {
      final result = await _exportService.export(
        imagePaths: imagePaths,
        options: options,
        onProgress: (done, total) {
          if (!mounted) return;
          _reportProgress(PdfExportProgress(done: done, total: total));
        },
      );
      state = AsyncValue<PdfExportResult?>.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue<PdfExportResult?>.error(error, stackTrace);
    } finally {
      _reportProgress(null);
    }
  }

  /// Clears the result so the screen stops showing the last message.
  void clear() => state = const AsyncValue<PdfExportResult?>.data(null);
}

/// Controller the PDF export button talks to.
final pdfExportControllerProvider =
    StateNotifierProvider.autoDispose<
      PdfExportController,
      AsyncValue<PdfExportResult?>
    >((ref) {
      return PdfExportController(
        exportService: ref.watch(pdfExportServiceProvider),
        reportProgress: (progress) =>
            ref.read(pdfExportProgressProvider.notifier).state = progress,
      );
    });
