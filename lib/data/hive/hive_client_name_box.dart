import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';

class HiveClientInRoomBox {
  String get name => 'client_in_room_box';
  CollectionBox<List>? _clientInRoomBox;

  Future<void> init({BoxCollection? collection, required String dbName}) async {
    if (collection == null) {
      final collection = await BoxCollection.open(dbName, {name});
      _clientInRoomBox = await collection.openBox(name);
    }
    _clientInRoomBox = await collection?.openBox(name);
  }

  Future<void> insertClientName(String roomId, String clientName) async {
    if (_clientInRoomBox == null) {
      Logs()
          .e('HiveClientInRoomBox:insertClientName: _clientInRoomBox is null');
    }
    final listClientNames = await _clientInRoomBox?.get(roomId);
    if (listClientNames == null) {
      await _clientInRoomBox?.put(roomId, [clientName]);
    } else {
      if (listClientNames.contains(clientName)) {
        Logs().v(
          'HiveClientNameBox:insertClientName::$clientName already exists',
        );
        return;
      }
      listClientNames.add(clientName);
      await _clientInRoomBox?.put(roomId, listClientNames);
    }
    Logs().v(
      'HiveClientNameBox:insertClientName::($roomId, $clientName) success',
    );
  }

  Future<void> deleteClientName(String roomId) async {
    if (_clientInRoomBox == null) {
      Logs()
          .e('HiveClientInRoomBox:deleteClientName: _clientInRoomBox is null');
    }
    final listClientNames = await _clientInRoomBox?.get(roomId);
    if (listClientNames?.isNotEmpty == true) {
      listClientNames!.remove(roomId);
      await _clientInRoomBox?.put(roomId, listClientNames);
    } else {
      await _clientInRoomBox?.delete(roomId);
    }
    Logs().v(
      'HiveClientNameBox:deleteClientName::$roomId success',
    );
  }

  Future<String?> getClientName(String roomId) async {
    if (_clientInRoomBox == null) {
      Logs().e('HiveClientInRoomBox:getClientName: _clientInRoomBox is null');
    }
    final listClientNames = await _clientInRoomBox?.get(roomId);
    return listClientNames?.first;
  }

  Future<void> clear({required Client client}) async {
    await Future.wait(client.rooms.map((room) => deleteClientName(room.id)));
  }
}
