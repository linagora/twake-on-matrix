import 'package:fluffychat/data/datasource/invitation/hive_invitation_status_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';

class HiveInvitationStatusRepositoryImpl
    extends HiveInvitationStatusRepository {
  final HiveInvitationStatusDatasource _hiveInvitationStatusDatasource = getIt
      .get<HiveInvitationStatusDatasource>();

  @override
  Future<void> deleteInvitationStatusByContactId({
    required String userId,
    required String contactId,
  }) {
    return _hiveInvitationStatusDatasource.deleteInvitationStatusByContactId(
      userId: userId,
      contactId: contactId,
    );
  }

  @override
  Future<InvitationStatus> getInvitationStatus({
    required String userId,
    required String contactId,
  }) {
    return _hiveInvitationStatusDatasource.getInvitationStatus(
      userId: userId,
      contactId: contactId,
    );
  }

  @override
  Future<void> storeInvitationStatus({
    required String userId,
    required InvitationStatus invitationStatus,
  }) {
    return _hiveInvitationStatusDatasource.storeInvitationStatus(
      userId: userId,
      invitationStatus: invitationStatus,
    );
  }
}
