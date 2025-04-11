import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_get_invitation_status_state.dart';
import 'package:fluffychat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin InvitationStatusMixin {
  final ValueNotifier<Either<Failure, Success>> getInvitationStatusNotifier =
      ValueNotifier(const Right(GetInvitationStatusInitial()));

  final HiveGetInvitationStatusInteractor _hiveGetInvitationStatusInteractor =
      getIt.get<HiveGetInvitationStatusInteractor>();

  final GetInvitationStatusInteractor _getInvitationStatusInteractor =
      getIt.get<GetInvitationStatusInteractor>();

  void getInvitationStatus({
    required String userId,
    required String contactId,
  }) {
    final initialState = getInvitationStatusNotifier.value
        .getSuccessOrNull<GetInvitationStatusInitial>();
    if (initialState == null) {
      return;
    }
    _hiveGetInvitationStatusInteractor
        .execute(
          userId: userId,
          contactId: contactId,
        )
        .listen(
          (state) => state.fold(
            (failure) {},
            (success) {
              if (success is HiveGetInvitationStatusSuccessState) {
                Logs().d(
                  'InvitationStatusMixin::getInvitationStatus - ${success.contactId} - ${success.invitationId}',
                );
                getInvitationNetworkStatus(
                  userId: userId,
                  contactId: success.contactId,
                  invitationId: success.invitationId,
                );
              }
            },
          ),
        );
  }

  void getInvitationNetworkStatus({
    required String userId,
    required String contactId,
    required String invitationId,
  }) {
    _getInvitationStatusInteractor
        .execute(
          userId: userId,
          contactId: contactId,
          invitationId: invitationId,
        )
        .listen(
          (state) => getInvitationStatusNotifier.value = state,
        );
  }

  void disposeInvitationStatus() {
    getInvitationStatusNotifier.dispose();
  }
}
