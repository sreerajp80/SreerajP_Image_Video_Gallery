import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_permissions.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_permission_info.dart';

/// Keeps the Permissions screen in step with the real manifest. If someone
/// adds, removes or strips a permission, this fails until the list (and the
/// screen's text) is updated too.
void main() {
  final String manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  // Every <uses-permission .../> block, attributes and all.
  final List<String> blocks = RegExp(
    r'<uses-permission\b(.*?)/>',
    dotAll: true,
  ).allMatches(manifest).map((m) => m.group(1)!).toList();

  String nameOf(String block) {
    final String full = RegExp(
      r'android:name="([^"]+)"',
    ).firstMatch(block)!.group(1)!;
    return full.replaceFirst('android.permission.', '');
  }

  int? maxSdkOf(String block) {
    final Match? m = RegExp(r'android:maxSdkVersion="(\d+)"').firstMatch(block);
    return m == null ? null : int.parse(m.group(1)!);
  }

  bool isRemoved(String block) => block.contains('tools:node="remove"');

  Map<String, AndroidPermissionName> namesOfKind(AppPermissionKind kind) {
    return <String, AndroidPermissionName>{
      for (final AppPermissionInfo info in kAppPermissions)
        if (info.kind == kind)
          for (final AndroidPermissionName n in info.androidNames) n.name: n,
    };
  }

  test('the manifest has permissions to compare against', () {
    expect(blocks, isNotEmpty);
  });

  test('every declared permission is listed, and nothing extra', () {
    final Set<String> declared = blocks
        .where((b) => !isRemoved(b))
        .map(nameOf)
        .toSet();
    final Set<String> listed = <String>{
      ...namesOfKind(AppPermissionKind.explicit).keys,
      ...namesOfKind(AppPermissionKind.implicit).keys,
    }..remove(kMergedOnlyPermission);

    expect(listed, declared);
  });

  test('every stripped permission is listed as removed', () {
    final Set<String> stripped = blocks.where(isRemoved).map(nameOf).toSet();
    expect(namesOfKind(AppPermissionKind.removed).keys.toSet(), stripped);
  });

  test('max Android versions match the manifest', () {
    final Map<String, AndroidPermissionName> listed =
        <String, AndroidPermissionName>{
          ...namesOfKind(AppPermissionKind.explicit),
          ...namesOfKind(AppPermissionKind.implicit),
        };
    for (final String block in blocks.where((b) => !isRemoved(b))) {
      final String name = nameOf(block);
      expect(listed[name]?.maxApi, maxSdkOf(block), reason: name);
    }
  });

  test('each friendly row appears once', () {
    final List<AppPermissionId> ids = kAppPermissions.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), AppPermissionId.values.toSet());
  });
}
