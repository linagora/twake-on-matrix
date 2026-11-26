import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/voice_message/datasources_impl/voice_message_datasource.provider.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository_impl.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';

part 'voice_message_repository.provider.g.dart';

@riverpod
VoiceMessageRepository voiceMessageRepository(Ref ref) =>
    VoiceMessageRepositoryImpl(ref.watch(voiceMessageDatasourceProvider));
