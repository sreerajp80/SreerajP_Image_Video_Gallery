import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/secure_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_auto_lock_scope.dart';
import 'package:video_player/video_player.dart';

/// Shows one item from inside the vault.
///
/// A picture is decrypted into memory and drawn from there, so no readable
/// copy of it ever exists on disk.
///
/// A video cannot be played from memory by the platform player, so it is
/// decrypted into a working file inside the app-private vault directory —
/// not the public cache, not the temporary directory — and that file is
/// shredded when this screen is disposed. If the app is killed before that can
/// happen, the sweep on the next vault unlock shreds it instead. This is the
/// one place vault content touches disk in the clear, and it is bounded on
/// both sides.
class VaultViewerScreen extends ConsumerStatefulWidget {
  /// Id of the vault record to show.
  final String itemId;

  const VaultViewerScreen({super.key, required this.itemId});

  @override
  ConsumerState<VaultViewerScreen> createState() => _VaultViewerScreenState();
}

class _VaultViewerScreenState extends ConsumerState<VaultViewerScreen> {
  VaultItem? _item;
  Uint8List? _imageBytes;
  VideoPlayerController? _videoController;

  /// Path of the decrypted working file, while one exists.
  String? _workingPath;

  bool _loading = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    // Order matters: the player has to let go of the file before it is
    // overwritten, and the shred has to be started even though dispose cannot
    // wait for it.
    _videoController?.dispose();
    _shredWorkingFile();
    super.dispose();
  }

  /// Shreds the decrypted working file, if there is one.
  ///
  /// Deliberately not awaited: `dispose` cannot be asynchronous. The repository
  /// is read before the widget goes, so the call survives this screen, and the
  /// sweep on the next unlock is the backstop if it does not finish.
  void _shredWorkingFile() {
    final path = _workingPath;
    if (path == null) return;
    _workingPath = null;
    final repository = ref.read(vaultRepositoryProvider);
    unawaitedShred(repository, path);
  }

  Future<void> _load() async {
    final repository = ref.read(vaultRepositoryProvider);
    try {
      final item = await repository.getItem(widget.itemId);
      if (item == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorKey = _errorMissing;
          });
        }
        return;
      }

      if (item.mediaType == MediaType.video) {
        await _loadVideo(repository, item);
      } else {
        final bytes = await repository.readImageBytes(item);
        if (!mounted) return;
        setState(() {
          _item = item;
          _imageBytes = bytes;
          _loading = false;
        });
      }
    } on VaultException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorKey = error.code == 'payload_tampered'
            ? _errorTampered
            : _errorMissing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorKey = _errorMissing;
      });
    }
  }

  Future<void> _loadVideo(VaultRepository repository, VaultItem item) async {
    final path = await repository.openVideoForPlayback(item);
    _workingPath = path;

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    if (!mounted) {
      // The screen went while the clip was opening. Clean up rather than
      // leaving a decrypted file behind.
      await controller.dispose();
      _shredWorkingFile();
      return;
    }

    await controller.setLooping(false);
    setState(() {
      _item = item;
      _videoController = controller;
      _loading = false;
    });
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lock = ref.watch(vaultLockControllerProvider);

    // The vault locked underneath this screen. Everything decrypted goes with
    // it, and the gate is what the user is left looking at.
    if (!lock.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return SecureScreen(
      child: VaultAutoLockScope(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(_item?.originalFilename ?? l10n.vaultTitle),
          ),
          body: Center(child: _buildBody(l10n)),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const CircularProgressIndicator();

    final errorKey = _errorKey;
    if (errorKey != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          errorKey == _errorTampered
              ? l10n.vaultViewerTampered
              : l10n.vaultViewerFailed,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    final controller = _videoController;
    if (controller != null) {
      return _VaultVideoView(controller: controller);
    }

    final bytes = _imageBytes;
    if (bytes != null) {
      return InteractiveViewer(
        maxScale: 8,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Text(
            l10n.vaultViewerFailed,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Text(
      l10n.vaultViewerFailed,
      style: const TextStyle(color: Colors.white70),
    );
  }

  static const String _errorMissing = 'missing';
  static const String _errorTampered = 'tampered';
}

/// Starts a shred without waiting for it.
///
/// A free function so `dispose` can fire it without holding a reference to a
/// widget that is on its way out.
void unawaitedShred(VaultRepository repository, String path) {
  // Errors are swallowed on purpose: the sweep on the next unlock is what
  // catches a shred that could not run, and there is no user here to tell.
  repository.closeVideoPlayback(path).catchError((_) {});
}

/// The clip, with a play control and a seek bar.
///
/// Deliberately simple. The full player with its gestures and speed control
/// belongs to the gallery viewer; putting it here would mean threading a vault
/// working file through providers meant for indexed media, and every one of
/// those paths is one more place a decrypted path could be held onto.
class _VaultVideoView extends StatefulWidget {
  final VideoPlayerController controller;

  const _VaultVideoView({required this.controller});

  @override
  State<_VaultVideoView> createState() => _VaultVideoViewState();
}

class _VaultVideoViewState extends State<_VaultVideoView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller.value;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AspectRatio(
          aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        VideoProgressIndicator(controller, allowScrubbing: true),
        IconButton(
          iconSize: 42,
          color: Colors.white,
          onPressed: () =>
              value.isPlaying ? controller.pause() : controller.play(),
          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }
}
