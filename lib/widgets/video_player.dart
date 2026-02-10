import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({super.key, required this.bytes, required this.event});

  final Uint8List bytes;

  final Event? event;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final videoController = VideoController(Player());

  @override
  void initState() {
    super.initState();
    Media.memory(widget.bytes).then(
      (v) => videoController.player.open(v),
      onError: (e, s) => Logs().e('Error opening video:', e, s),
    );
  }

  @override
  void dispose() {
    super.dispose();
    videoController.player.dispose();
    videoController.notifier.dispose();
    videoController.id.dispose();
    videoController.rect.dispose();
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
