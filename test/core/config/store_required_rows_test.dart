import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A public store needs a reachable privacy policy and a support contact
/// (store readiness §1, guideline.md §1.6). Both live in the About screen's
/// config; this keeps them from being dropped by accident.
void main() {
  final details =
      (jsonDecode(File('assets/config/app_config.json').readAsStringSync())
              as Map<String, dynamic>)['details']
          as Map<String, dynamic>;

  test('the About config has a support email', () {
    final email = details['email'];
    expect(email, isA<String>());
    expect(email as String, contains('@'));
  });

  test('the privacy policy row points at PRIVACY.md on the master branch', () {
    final url = details['privacyPolicy'] as String?;
    expect(url, startsWith('https://github.com/'));
    expect(url, endsWith('/blob/master/PRIVACY.md'));
    expect(File('PRIVACY.md').existsSync(), isTrue);
  });
}
