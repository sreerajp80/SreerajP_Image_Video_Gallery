import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/providers/provider_retry.dart';

void main() {
  test('no provider is ever retried', () {
    for (var attempt = 0; attempt < 5; attempt++) {
      expect(noProviderRetry(attempt, StateError('x')), isNull);
    }
  });

  test('the app ProviderScope uses the no-retry rule', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('retry: noProviderRetry'));
  });
}
