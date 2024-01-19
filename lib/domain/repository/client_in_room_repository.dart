import 'package:matrix/matrix.dart';

abstract class ClientInRoomRepository {
  Future<void> insertClientName(String roomId, String clientName);

  Future<void> deleteClientName(String roomId);

  Future<String?> getClientName(String roomId);

  Future<void> clear({required Client client});
}
