import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';

/// Applies the "Hide content" setting to the whole app (G28).
///
/// While the setting is on, this holds one request for `FLAG_SECURE`, so
/// screenshots, screen recording and the recent-apps preview are blocked on
/// every screen. Requests are counted on the Android side, so the vault's own
/// request (`SecureScreen`) is never cancelled by switching this off: the
/// vault stays protected either way.
class AppScreenProtection extends ConsumerStatefulWidget {
  final Widget child;

  const AppScreenProtection({super.key, required this.child});

  @override
  ConsumerState<AppScreenProtection> createState() =>
      _AppScreenProtectionState();
}

class _AppScreenProtectionState extends ConsumerState<AppScreenProtection> {
  /// Whether this widget holds a request, so a release is never sent without
  /// a matching acquire.
  bool _held = false;

  /// Read once while the widget is alive. Riverpod 3 does not allow `ref` in
  /// `dispose`, and the request must still be given back there.
  late final Future<void> Function() _acquire;
  late final Future<void> Function() _release;

  void _apply(bool protect) {
    if (protect == _held) return;
    _held = protect;
    if (protect) {
      _acquire();
    } else {
      _release();
    }
  }

  @override
  void initState() {
    super.initState();
    final service = ref.read(secureWindowServiceProvider);
    _acquire = service.acquire;
    _release = service.release;
    _apply(ref.read(appSettingsProvider).protectAllScreens);
  }

  @override
  void dispose() {
    if (_held) {
      _release();
      _held = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      appSettingsProvider.select((s) => s.protectAllScreens),
      (_, next) => _apply(next),
    );
    return widget.child;
  }
}
