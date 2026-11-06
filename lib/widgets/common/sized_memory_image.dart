import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// An [Image.memory] that is decoded at the size it is shown, not at the
/// size of the file (engineering standard §10.4).
///
/// The box size comes from the layout and the screen's pixel ratio. A PDF
/// can carry an 80-megapixel picture; shown in a 64 dp tile it is decoded to
/// a few hundred pixels instead of hundreds of megabytes.
///
/// The decoded image keeps its shape and fits inside the target box. With
/// [BoxFit.cover] the box is doubled first, because a cover fit fills the
/// box with the picture's *shorter* side: doubling keeps any photo up to 2:1
/// sharp without knowing its shape before decoding. Never used for the
/// full-screen viewer, editor or compare screens, where the user zooms in.
class SizedMemoryImage extends StatelessWidget {
  final Uint8List bytes;
  final BoxFit fit;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// The shown size, when the caller knows it. Otherwise the layout's
  /// constraints are used.
  final double? width;
  final double? height;

  const SizedMemoryImage(
    this.bytes, {
    super.key,
    this.fit = BoxFit.cover,
    this.gaplessPlayback = false,
    this.errorBuilder,
    this.width,
    this.height,
  });

  /// Works out the decode size in physical pixels, or null when the box has
  /// no finite size and the image must be decoded as it is.
  static ({int width, int height})? decodeSize({
    required double boxWidth,
    required double boxHeight,
    required double pixelRatio,
    required BoxFit fit,
  }) {
    if (!boxWidth.isFinite || !boxHeight.isFinite) return null;
    if (boxWidth <= 0 || boxHeight <= 0) return null;
    final factor = fit == BoxFit.cover ? 2.0 : 1.0;
    return (
      width: (boxWidth * pixelRatio * factor).ceil(),
      height: (boxHeight * pixelRatio * factor).ceil(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // With a known size there is no need to measure. This also keeps the
    // widget usable where a parent asks for intrinsic sizes (a ListTile
    // leading), which a LayoutBuilder cannot answer.
    if (width != null && height != null) {
      return _image(context, width!, height!);
    }
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        context,
        width ?? constraints.maxWidth,
        height ?? constraints.maxHeight,
      ),
    );
  }

  Widget _image(BuildContext context, double boxWidth, double boxHeight) {
    final target = decodeSize(
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      fit: fit,
    );
    final ImageProvider provider = target == null
        ? MemoryImage(bytes)
        : ResizeImage(
            MemoryImage(bytes),
            width: target.width,
            height: target.height,
            policy: ResizeImagePolicy.fit,
          );
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );
  }
}
