import 'package:fluffychat/data/hive/dto/invitation_status/invitation_status_hive_obj.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';

extension InvitationStatusHiveObjExtension on InvitationStatusHiveObj {
  InvitationStatus toInvitationStatus() {
    return InvitationStatus(invitationId: invitationId, contactId: contactId);
  }
}
