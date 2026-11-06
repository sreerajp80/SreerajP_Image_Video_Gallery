import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A refused "open with" link is reported to Dart, but with nothing about
/// the link itself. This reads the Kotlin source; it does not run Android.
void main() {
  final String handler = File(
    'android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt',
  ).readAsStringSync();

  test('a refused link returns the refusal marker', () {
    expect(
      handler,
      contains(
        'if (!IncomingUriRules.isAllowed(activity, uri)) return REFUSED_INTENT',
      ),
    );
  });

  test('the refusal marker holds only the refused flag', () {
    expect(
      handler,
      contains(
        'val REFUSED_INTENT: Map<String, Any?> = mapOf("refused" to true)',
      ),
    );
  });
}
