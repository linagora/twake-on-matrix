import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/forward/forward_repository.provider.dart';
import 'package:twake_chat/domain/forward/usecases/forward_messages_usecase.dart';

part 'forward_messages_usecase.provider.g.dart';

@riverpod
ForwardMessagesUseCase forwardMessagesUseCase(Ref ref) =>
    ForwardMessagesUseCase(ref.watch(forwardRepositoryProvider));
