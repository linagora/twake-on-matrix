import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.dart';

part 'join_call_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
JoinCallUseCase joinCallUseCase(Ref ref) =>
    JoinCallUseCase(ref.watch(callRepositoryProvider));
