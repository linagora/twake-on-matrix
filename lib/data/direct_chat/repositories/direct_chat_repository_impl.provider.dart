import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/direct_chat_datasource_impl.provider.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';

part 'direct_chat_repository_impl.provider.g.dart';

@riverpod
DirectChatRepository directChatRepository(Ref ref) =>
    DirectChatRepositoryImpl(ref.watch(directChatDatasourceProvider));
