import 'package:fluffychat/data/datasource/invitation/hive_invitation_status_datasource.dart';
import 'package:fluffychat/data/hive/dto/invitation_status/invitation_status_hive_obj.dart';
import 'package:fluffychat/data/hive/extension/invitation_status_hive_obj_extension.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/exception/invitation/invitation_status_not_found.dart';
import 'package:fluffychat/domain/model/extensions/invitation/invitation_extension.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';
import 'package:fluffychat/utils/copy_map.dart';
import 'package:matrix/matrix.dart';

class HiveInvitationStatusDatasourceImpl
    extends HiveInvitationStatusDatasource {
  @override
  Future<InvitationStatus> getInvitationStatus({
    required String userId,
    required String contactId,
  }) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();
    final invitationStatus = await hiveCollectionFederationDatabase
        .invitationStatus
        .get(TupleKey(userId, contactId).toString());

    if (invitationStatus == null) {
      throw InvitationStatusNotFound(userId: userId, contactId: contactId);
    }

    return InvitationStatusHiveObj.fromJson(
      copyMap(invitationStatus),
    ).toInvitationStatus();
  }

  @override
  Future<void> storeInvitationStatus({
    required String userId,
    required InvitationStatus invitationStatus,
  }) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();

    return hiveCollectionFederationDatabase.invitationStatus.put(
      TupleKey(userId, invitationStatus.contactId).toString(),
      invitationStatus.toHiveObj().toJson(),
    );
  }

  @override
  Future<void> deleteInvitationStatusByContactId({
    required String userId,
    required String contactId,
  }) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();

    return hiveCollectionFederationDatabase.invitationStatus.delete(
      TupleKey(userId, contactId).toString(),
    );
  }
}
