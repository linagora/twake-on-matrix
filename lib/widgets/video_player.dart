import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  VideoPlayer({super.key, this.bytes, this.url})
    : assert(
        (bytes == null) != (url == null),
        'Provide exactly one of bytes or url',
      ) {
    if ((bytes == null) == (url == null)) {
      throw ArgumentError('Provide exactly one of bytes or url');
    }
  }

  /// In-memory video bytes (web path).
  final Uint8List? bytes;

  /// File URI for playback (mobile/desktop), e.g. file:///path/to/video.mp4
  final String? url;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late Player player;
  late VideoController videoController;

  /// Creates a [Player] with explicit log level so decoder selection warnings
  /// (e.g. silent HW → SW fallback on Android) are captured in logs.
  Player _createPlayer() => Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
  );

  /// Creates a [VideoController] with explicit hwdec to force MediaCodec on Android.
  ///
  /// `hwdec=auto-safe` (the default) can silently fall back to software
  /// decoding on some devices, causing slow playback. `mediacodec-copy` forces
  /// HW decode via MediaCodec with a CPU-side copy, which has wider device
  /// compatibility than plain `mediacodec`.
  VideoController _createController(Player p) => VideoController(
    p,
    configuration: const VideoControllerConfiguration(hwdec: 'mediacodec-copy'),
  );

  /// Opens the media source on [targetPlayer], logging any errors.
  ///
  /// Accepts an explicit [targetPlayer] so that a stale async call that
  /// resumes after the widget has already recreated [player] cannot
  /// accidentally open media on the new instance.
  Future<void> _openMedia({
    required Player targetPlayer,
    required String? url,
    required Uint8List? bytes,
  }) async {
    try {
      if (url != null) {
        await targetPlayer.open(Media(url));
      } else {
        final media = await Media.memory(bytes!);
        await targetPlayer.open(media);
      }
    } catch (e, s) {
      Logs().e('Error opening video media:', e, s);
    }
  }

  @override
  void initState() {
    super.initState();
    player = _createPlayer();
    videoController = _createController(player);
    unawaited(
      _openMedia(targetPlayer: player, url: widget.url, bytes: widget.bytes),
    );
  }

  @override
  Future<void> didUpdateWidget(covariant VideoPlayer oldWidget) async {
    super.didUpdateWidget(oldWidget);
    final urlChanged = widget.url != oldWidget.url && widget.url != null;
    final bytesChanged =
        widget.bytes != oldWidget.bytes && widget.bytes != null;
    if (!urlChanged && !bytesChanged) return;

    await player.dispose();
    player = _createPlayer();
    videoController = _createController(player);
    await _openMedia(
      targetPlayer: player,
      url: widget.url,
      bytes: widget.bytes,
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RepaintBoundary isolates the video surface so that controls
      // rebuilding above it do not trigger a repaint of the video layer.
      body: RepaintBoundary(
        child: Video(
          fill: Colors.black,
          controller: videoController,
          pauseUponEnteringBackgroundMode: true,
          resumeUponEnteringForegroundMode: true,
        ),
      ),
    );
  }
}
