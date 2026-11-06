import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/crop_overlay.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/markup_canvas.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/redaction_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_color_picker.dart';

/// Runs Flutter's own accessibility checks (standard §7.1, §7.3) on the
/// controls that had small or unlabelled targets.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectGuidelines(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  testWidgets('tag colour picker', (tester) async {
    await pump(
      tester,
      TagColorPicker(
        selectedColorValue: TagColorPalette.colors.first,
        onChanged: (_) {},
      ),
    );
    await expectGuidelines(tester);
  });

  testWidgets('tag colour swatches are named and show the selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TagColorPicker(
        selectedColorValue: TagColorPalette.colors.first,
        onChanged: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Red')),
      isSemantics(
        label: 'Red',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('markup controls', (tester) async {
    await pump(
      tester,
      MarkupControlsPanel(
        settings: const MarkupToolSettings(),
        onSettingsChanged: (_) {},
        onAddText: () {},
        onRemoveLast: () {},
        canRemove: true,
      ),
    );
    await expectGuidelines(tester);
  });

  testWidgets('redaction controls', (tester) async {
    await pump(
      tester,
      RedactionControlsPanel(
        settings: const RedactionToolSettings(),
        regionCount: 1,
        onSettingsChanged: (_) {},
        onRemoveLast: () {},
      ),
    );
    await expectGuidelines(tester);
  });

  testWidgets('crop controls', (tester) async {
    await pump(
      tester,
      CropControlsPanel(
        transform: CropTransform.identity,
        onAspectSelected: (_) {},
        onRotateLeft: () {},
        onRotateRight: () {},
        onFlipHorizontal: () {},
        onFlipVertical: () {},
        onStraightenChanged: (_) {},
        onStraightenEnd: (_) {},
        onPerspectiveChanged: (_) {},
        onPerspectiveEnd: (_) {},
        onReset: () {},
      ),
    );
    await expectGuidelines(tester);
  });
}
