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

  @override
  void initState() {
    super.initState();
    player = Player();
    videoController = VideoController(player);
    if (widget.url != null) {
      videoController.player
          .open(Media(widget.url!))
          .then(
            (_) {},
            onError: (e, s) => Logs().e('Error opening video url:', e, s),
          );
    } else {
      final currentPlayer = player;
      Media.memory(widget.bytes!).then(
        (v) => currentPlayer.open(v),
        onError: (e, s) => Logs().e('Error opening video bytes:', e, s),
      );
    }
  }

  @override
  Future<void> didUpdateWidget(covariant VideoPlayer oldWidget) async {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url && widget.url != null) {
      await player.dispose();
      player = Player();
      videoController = VideoController(player);
      videoController.player
          .open(Media(widget.url!))
          .then(
            (_) {},
            onError: (e, s) => Logs().e('Error opening video url:', e, s),
          );
    } else if (widget.bytes != oldWidget.bytes && widget.bytes != null) {
      await player.dispose();
      player = Player();
      videoController = VideoController(player);
      Media.memory(widget.bytes!).then(
        (v) => player.open(v),
        onError: (e, s) => Logs().e('Error opening video bytes:', e, s),
      );
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Video(
        fill: Colors.black,
        pauseUponEnteringBackgroundMode: true,
        resumeUponEnteringForegroundMode: true,
        controller: videoController,
      ),
    );
  }
}
