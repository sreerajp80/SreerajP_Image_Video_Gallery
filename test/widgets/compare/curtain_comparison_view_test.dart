import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/curtain_comparison_view.dart';

void main() {
  final photoA = MediaItem(
    id: 'photo_a',
    path: '/storage/emulated/0/DCIM/photo_a.jpg',
    displayName: 'Burst_001.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2048000,
    dateAdded: DateTime(2026, 9, 6),
    dateModified: DateTime(2026, 9, 6),
  );

  final photoB = MediaItem(
    id: 'photo_b',
    path: '/storage/emulated/0/DCIM/photo_b.jpg',
    displayName: 'Burst_002.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2200000,
    dateAdded: DateTime(2026, 9, 6),
    dateModified: DateTime(2026, 9, 6),
  );

  testWidgets('CurtainComparisonView renders handle and supports drag', (
    tester,
  ) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fullImageBytesProvider(photoA).overrideWith((ref) => Uint8List(0)),
          fullImageBytesProvider(photoB).overrideWith((ref) => Uint8List(0)),
          thumbnailProvider(photoA).overrideWith((ref) => Uint8List(0)),
          thumbnailProvider(photoB).overrideWith((ref) => Uint8List(0)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CurtainComparisonView(
              itemA: photoA,
              itemB: photoB,
              transformationController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify handle icon exists
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);

    // Drag the divider handle
    await tester.drag(
      find.byIcon(Icons.compare_arrows_rounded),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();

    // Still renders properly after drag
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
  });
}
