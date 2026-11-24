import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/set_call_speaker_usecase.dart';

part 'set_call_speaker_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
SetCallSpeakerUseCase setCallSpeakerUseCase(Ref ref) =>
    SetCallSpeakerUseCase(ref.watch(callRepositoryProvider));
