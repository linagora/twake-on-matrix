import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:twake_chat/domain/model/call/call_participant.dart';

class CallVideo extends StatelessWidget {
  const CallVideo({required this.video, super.key});

  final CallVideoTrack video;

  @override
  Widget build(BuildContext context) {
    final track = video.handle;
    if (track is! lk.VideoTrack) return const SizedBox.shrink();
    return lk.VideoTrackRenderer(
      track,
      key: ValueKey(track.mediaStreamTrack.id),
      fit: lk.VideoViewFit.cover,
    );
  }
}
