import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/voice_message/datasources/voice_message_datasource.dart';
import 'package:twake_chat/data/voice_message/datasources_impl/voice_message_datasource_impl.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';

part 'voice_message_datasource.provider.g.dart';

@riverpod
VoiceMessageDatasource voiceMessageDatasource(Ref ref) =>
    VoiceMessageDatasourceImpl(ref.watch(matrixClientProvider));
