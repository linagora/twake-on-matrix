import 'package:fluffychat/domain/model/invitation/invitation_status.dart';

abstract class HiveInvitationStatusRepository {
  Future<void> storeInvitationStatus({
    required String userId,
    required InvitationStatus invitationStatus,
  });

  Future<InvitationStatus> getInvitationStatus({
    required String userId,
  });

  Future<void> deleteInvitationStatusByContactId({
    required String userId,
    required String contactId,
  });
}
