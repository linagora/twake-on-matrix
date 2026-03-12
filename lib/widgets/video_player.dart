import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({super.key, this.bytes, this.url, required this.event})
    : assert(bytes != null || url != null, 'bytes or url must be provided');

  /// In-memory video bytes (web path).
  final Uint8List? bytes;

  /// File URI for playback (mobile/desktop), e.g. file:///path/to/video.mp4
  final String? url;

  final Event? event;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late final Player player;
  late final VideoController videoController;

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
      Media.memory(widget.bytes!).then(
        (v) => videoController.player.open(v),
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
