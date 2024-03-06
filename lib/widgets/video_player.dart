import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({
    super.key,
    required this.path,
    required this.event,
  });

  final String path;

  final Event? event;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final VideoController videoController = VideoController(Player());

  @override
  void initState() {
    super.initState();
    videoController.player.open(Media(widget.path));
  }

  @override
  void dispose() {
    super.dispose();
    videoController.player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Video(
            fill: Colors.black,
            pauseUponEnteringBackgroundMode: true,
            resumeUponEnteringForegroundMode: true,
            controller: videoController,
          ),
          MediaViewerAppBar(
            event: widget.event,
          ),
        ],
      ),
    );
  }
}
