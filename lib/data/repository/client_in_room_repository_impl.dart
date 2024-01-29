import 'package:fluffychat/data/datasource/client_in_room_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/client_in_room_repository.dart';
import 'package:matrix/matrix.dart';

class ClientInRoomRepositoryImpl implements ClientInRoomRepository {
  final ClientInRoomDatasource _clientInRoomDataSource =
      getIt.get<ClientInRoomDatasource>();

  ClientInRoomRepositoryImpl();

  @override
  Future<void> clear({required Client client}) async {
    await _clientInRoomDataSource.clear(client: client);
  }

  @override
  Future<void> deleteClientName(String roomId) async {
    await _clientInRoomDataSource.deleteClientName(roomId);
  }

  @override
  Future<String?> getClientName(String roomId) async {
    return await _clientInRoomDataSource.getClientName(roomId);
  }

  @override
  Future<void> insertClientName(String roomId, String clientName) async {
    await _clientInRoomDataSource.insertClientName(roomId, clientName);
  }
}
