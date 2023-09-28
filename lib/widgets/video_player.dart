import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({
    super.key,
    required this.path,
  });

  final String path;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final VideoController videoController = VideoController(Player());
  bool isFullScreen = false;

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
    return Container(
      decoration: const BoxDecoration(
        color: MessageContentStyle.backgroundColorVideo,
      ),
      child: Video(
        pauseUponEnteringBackgroundMode: true,
        resumeUponEnteringForegroundMode: true,
        controller: videoController,
      ),
    );
  }
}
