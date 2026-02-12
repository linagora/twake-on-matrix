import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_get_invitation_status_state.dart';
import 'package:fluffychat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin InvitationStatusMixin {
  final ValueNotifier<Either<Failure, Success>> getInvitationStatusNotifier =
      ValueNotifier(const Right(GetInvitationStatusInitial()));

  final HiveGetInvitationStatusInteractor _hiveGetInvitationStatusInteractor =
      getIt.get<HiveGetInvitationStatusInteractor>();

  final GetInvitationStatusInteractor _getInvitationStatusInteractor = getIt
      .get<GetInvitationStatusInteractor>();

  final PostAddressBookInteractor _postAddressBookInteractor = getIt
      .get<PostAddressBookInteractor>();

  final HiveDeleteInvitationStatusInteractor
  _hiveDeleteInvitationStatusInteractor = getIt
      .get<HiveDeleteInvitationStatusInteractor>();

  final DeleteThirdPartyContactBoxInteractor
  _deleteThirdPartyContactBoxInteractor = getIt
      .get<DeleteThirdPartyContactBoxInteractor>();

  void getInvitationStatus({
    required String userId,
    required String contactId,
    required PresentationContact contact,
  }) {
    if (PlatformInfos.isWeb) {
      return;
    }
    final initialState = getInvitationStatusNotifier.value
        .getSuccessOrNull<GetInvitationStatusInitial>();
    if (initialState == null) {
      return;
    }
    _hiveGetInvitationStatusInteractor
        .execute(userId: userId, contactId: contactId)
        .listen(
          (state) => state.fold((failure) {}, (success) {
            if (success is HiveGetInvitationStatusSuccessState) {
              Logs().d(
                'InvitationStatusMixin::getInvitationStatus - ${success.contactId} - ${success.invitationId}',
              );
              getInvitationNetworkStatus(
                userId: userId,
                contactId: success.contactId,
                invitationId: success.invitationId,
                contact: contact,
              );
            }
          }),
        );
  }

  void getInvitationNetworkStatus({
    required String userId,
    required String contactId,
    required String invitationId,
    required PresentationContact contact,
  }) {
    _getInvitationStatusInteractor
        .execute(
          userId: userId,
          contactId: contactId,
          invitationId: invitationId,
        )
        .listen((state) {
          getInvitationStatusNotifier.value = state;
          _handleInvitationNetworkStatusState(
            state: state,
            userId: userId,
            contactId: contactId,
            contact: contact,
          );
        });
  }

  void _handleInvitationNetworkStatusState({
    required Either<Failure, Success> state,
    required String userId,
    required String contactId,
    required PresentationContact contact,
  }) {
    state.fold(
      (failure) {
        if (failure is GetInvitationStatusFailureState &&
            failure.exception is DioException) {
          final dioException = failure.exception as DioException;
          if (dioException.response?.statusCode == 404) {
            _onHiveDeleteInvitationStatus(userId: userId, contactId: contactId);
          }
        }
      },
      (success) {
        Logs().d(
          'InvitationStatusMixin::getInvitationNetworkStatus - $success',
        );
        if (success is GetInvitationStatusSuccessState) {
          if (success.invitationStatusResponse.invitation?.hasMatrixId ==
              true) {
            _postAddressBookOnMobile(
              contact: contact,
              matrixId: success.invitationStatusResponse.invitation!.matrixId!,
              userId: userId,
              contactId: contactId,
            );
          }

          if (success
                  .invitationStatusResponse
                  .invitation
                  ?.expiredTimeToInvite ==
              true) {
            Logs().d(
              'InvitationStatusMixin::getInvitationNetworkStatus - contactID ${success.invitationStatusResponse.invitation?.id} expired',
            );
            _onHiveDeleteInvitationStatus(userId: userId, contactId: contactId);
          }
        }
      },
    );
  }

  void _onHiveDeleteInvitationStatus({
    required String userId,
    required String contactId,
  }) {
    _hiveDeleteInvitationStatusInteractor
        .execute(userId: userId, contactId: contactId)
        .listen(
          (state) => state.fold(
            (failure) => Logs().e(
              'InvitationStatusMixin::deleteInvitationStatus $failure',
            ),
            (success) => Logs().d(
              'InvitationStatusMixin::deleteInvitationStatus $success',
            ),
          ),
        );
  }

  void _postAddressBookOnMobile({
    required PresentationContact contact,
    required String matrixId,
    required String userId,
    required String contactId,
  }) {
    _postAddressBookInteractor
        .execute(
          addressBooks: [
            AddressBook(mxid: matrixId, displayName: contact.displayName),
          ],
        )
        .listen((state) {
          Logs().i('InvitationStatusMixin::_postAddressBook', state);

          state.fold(
            (failure) {
              Logs().e('InvitationStatusMixin::_postAddressBook', failure);
            },
            (success) {
              Logs().d('ContactsManager::_postAddressBook', success);
              _onDeleteThirdPartyContactBox();
            },
          );
        });
  }

  void _onDeleteThirdPartyContactBox() {
    _deleteThirdPartyContactBoxInteractor.execute().listen((state) {
      state.fold(
        (failure) => Logs().e(
          'InvitationStatusMixin::_onDeleteThirdPartyContactBox $failure',
        ),
        (success) => Logs().d(
          'InvitationStatusMixin::_onDeleteThirdPartyContactBox $success',
        ),
      );
    });
  }

  void disposeInvitationStatus() {
    getInvitationStatusNotifier.dispose();
  }
}
