import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository.provider.dart';
import 'package:twake_chat/domain/voice_message/usecases/find_next_voice_message_use_case.dart';

part 'find_next_voice_message_use_case.provider.g.dart';

@riverpod
FindNextVoiceMessageUseCase findNextVoiceMessageUseCase(Ref ref) =>
    FindNextVoiceMessageUseCase(ref.watch(voiceMessageRepositoryProvider));
