import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

part 'video_call_slug_service.provider.g.dart';

@riverpod
VideoCallSlugService videoCallSlugService(Ref ref) => VideoCallSlugService();
