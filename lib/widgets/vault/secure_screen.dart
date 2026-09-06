import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';

/// Blocks screenshots and screen recording while its child is on screen.
///
/// Wrap every vault screen in one of these. The flag goes on when the widget
/// mounts and off when it is disposed, and the requests are counted on the
/// Android side, so a vault viewer opening on top of the vault grid does not
/// switch the protection off when it closes and leaves the grid exposed.
///
/// It is scoped rather than app-wide on purpose. Setting the flag for the
/// whole app would stop the user screenshotting an ordinary holiday photo,
/// which is not what anybody asked for.
class SecureScreen extends ConsumerStatefulWidget {
  /// The screen being protected.
  final Widget child;

  const SecureScreen({super.key, required this.child});

  @override
  ConsumerState<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends ConsumerState<SecureScreen> {
  /// Whether this widget currently holds a request.
  ///
  /// Tracked so the release in `dispose` can never run without a matching
  /// acquire, which would drive the native counter below zero and turn the
  /// protection off under a screen that still needs it.
  bool _acquired = false;

  @override
  void initState() {
    super.initState();
    final service = ref.read(secureWindowServiceProvider);
    _acquired = true;
    service.acquire();
  }

  @override
  void dispose() {
    if (_acquired) {
      // Read, not watch: the widget is going away, and this must not be tied
      // to a rebuild that will never come.
      ref.read(secureWindowServiceProvider).release();
      _acquired = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
