import 'package:fluffychat/data/datasource/client_in_room_datasource.dart';
import 'package:fluffychat/data/hive/hive_client_name_box.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';

class ClientInRoomDatasourceImpl implements ClientInRoomDatasource {
  ClientInRoomDatasourceImpl();

  HiveClientInRoomBox? _hiveClientInRoomBox;

  Future<HiveClientInRoomBox> getHiveClientInRoomBox() async {
    if (_hiveClientInRoomBox != null) {
      return _hiveClientInRoomBox!;
    }
    final hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    _hiveClientInRoomBox = hiveCollectionToMDatabase.hiveClientInRoomBox;
    return _hiveClientInRoomBox!;
  }

  @override
  Future<void> insertClientName(String roomId, String clientName) async {
    final hiveClientInRoomBox = await getHiveClientInRoomBox();
    await hiveClientInRoomBox.insertClientName(roomId, clientName);
  }

  @override
  Future<void> deleteClientName(String roomId) async {
    final hiveClientInRoomBox = await getHiveClientInRoomBox();
    await hiveClientInRoomBox.deleteClientName(roomId);
  }

  @override
  Future<String?> getClientName(String roomId) async {
    final hiveClientInRoomBox = await getHiveClientInRoomBox();
    return await hiveClientInRoomBox.getClientName(roomId);
  }

  @override
  Future<void> clear({required Client client}) async {
    final hiveClientInRoomBox = await getHiveClientInRoomBox();
    await hiveClientInRoomBox.clear(client: client);
  }
}
