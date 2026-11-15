import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.provider.dart';
import 'package:twake_chat/domain/direct_chat/usecases/create_direct_chat_usecase.dart';

part 'create_direct_chat_usecase.provider.g.dart';

@riverpod
CreateDirectChatUseCase createDirectChatUseCase(Ref ref) =>
    CreateDirectChatUseCase(ref.watch(directChatRepositoryProvider));
