import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/video_call/video_call_api.dart';
import 'package:twake_chat/di/global/tom_network_providers.dart';

part 'video_call_api.provider.g.dart';

@riverpod
VideoCallApi videoCallApi(Ref ref) =>
    VideoCallApi(ref.watch(tomDioClientProvider));
