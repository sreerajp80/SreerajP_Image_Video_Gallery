import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';

/// Blocks screenshots and screen recording while its child is on screen.
///
/// Wrap every vault screen in one of these. The flag goes on when the widget
/// mounts and off when it is disposed, and the requests are counted on the
/// Android side, so a vault viewer opening on top of the vault grid does not
/// switch the protection off when it closes and leaves the grid exposed.
///
/// The vault is always protected. Protecting the rest of the app is a
/// separate user choice, off by default (`AppScreenProtection`).
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

  /// Read once in `initState`. Riverpod 3 does not allow `ref` in `dispose`,
  /// and without this the release never ran: leaving the vault kept the
  /// protection on for the rest of the session.
  late final Future<void> Function() _acquire;
  late final Future<void> Function() _release;

  @override
  void initState() {
    super.initState();
    final service = ref.read(secureWindowServiceProvider);
    _acquire = service.acquire;
    _release = service.release;
    _acquired = true;
    _acquire();
  }

  @override
  void dispose() {
    if (_acquired) {
      _release();
      _acquired = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
