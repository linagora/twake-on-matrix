import 'package:twake_chat/data/direct_chat/datasources/direct_chat_datasource.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';

class DirectChatRepositoryImpl implements DirectChatRepository {
  const DirectChatRepositoryImpl(this._datasource);

  final DirectChatDatasource _datasource;

  @override
  Future<String> createDirectChat({required String contactMxId}) =>
      _datasource.createDirectChat(contactMxId: contactMxId);

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) =>
      _datasource.isUsableDirectChat(roomId: roomId, contactMxId: contactMxId);
}
