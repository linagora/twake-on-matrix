import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/set_call_media_usecase.dart';

part 'set_call_media_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
SetCallMediaUseCase setCallMediaUseCase(Ref ref) =>
    SetCallMediaUseCase(ref.watch(callRepositoryProvider));
