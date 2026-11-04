import 'package:twake_chat/data/datasource/forward/forward_datasource.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

class ForwardRepositoryImpl implements ForwardRepository {
  const ForwardRepositoryImpl(this._datasource);

  final ForwardDatasource _datasource;

  @override
  bool isJoined(String roomId) => _datasource.isJoined(roomId);

  @override
  Future<void> sendMessage({
    required String roomId,
    required Map<String, Object?> content,
  }) => _datasource.sendMessage(roomId: roomId, content: content);
}
