import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/client_in_room_repository.dart';
import 'package:matrix/matrix.dart';

class UpdateClientInRoomInteractor {
  final clientInRoomRepository = getIt.get<ClientInRoomRepository>();

  Future<void> execute({
    required SyncUpdate syncUpdate,
    required String clientName,
  }) async {
    try {
      if (syncUpdate.rooms?.invite?.isNotEmpty == true) {
        await Future.wait(
          syncUpdate.rooms!.invite!.entries.map(
            (invitedRoomUpdateEntry) async {
              await clientInRoomRepository.insertClientName(
                invitedRoomUpdateEntry.key,
                clientName,
              );
            },
          ).toList(),
        );
      }
      if (syncUpdate.rooms?.join?.isNotEmpty == true) {
        await Future.wait(
          syncUpdate.rooms!.join!.entries.map(
            (joinedRoomUpdateEntry) async {
              await clientInRoomRepository.insertClientName(
                joinedRoomUpdateEntry.key,
                clientName,
              );
            },
          ).toList(),
        );
      }

      if (syncUpdate.rooms?.leave?.isNotEmpty == true) {
        await Future.wait(
          syncUpdate.rooms!.leave!.entries.map(
            (leftRoomUpdateEntry) async {
              await clientInRoomRepository.deleteClientName(
                leftRoomUpdateEntry.key,
              );
            },
          ).toList(),
        );
      }
    } catch (error) {
      Logs().e("UpdateClientInRoomInteractor: execute(): $error");
    }
  }
}
