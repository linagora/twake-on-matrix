import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/domain/model/extensions/contact/contacts_extension.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_success.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

mixin class ContactsViewControllerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  static const _defaultLimitRecentContacts = 6;

  final TextEditingController textEditingController = TextEditingController();

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  final SearchRecentChatInteractor _searchRecentChatInteractor =
      getIt.get<SearchRecentChatInteractor>();

  ValueNotifier<WarningContactsBannerState> warningBannerNotifier =
      ValueNotifier(WarningContactsBannerState.hide);

  // FIXME: Consider can use FocusNode instead ?
  final ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);

  final presentationRecentContactNotifier =
      ValueNotifierCustom<List<PresentationSearch>>([]);

  final presentationContactNotifier =
      ValueNotifierCustom<Either<Failure, Success>>(
    const Right(ContactsInitial()),
  );

  final presentationPhonebookContactNotifier =
      ValueNotifierCustom<Either<Failure, Success>>(
    const Right(GetPhonebookContactsInitial()),
  );

  final FocusNode searchFocusNode = FocusNode();

  final Debouncer<String> _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );

  final contactsManager = getIt.get<ContactsManager>();

  PermissionStatus contactsPermissionStatus = PermissionStatus.granted;

  void initialFetchContacts({
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) async {
    if (PlatformInfos.isMobile &&
        !contactsManager.isDoNotShowWarningContactsBannerAgain) {
      await _handleRequestContactsPermission();
    }
    _refreshAllContacts(
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
    _listenContactsDataChange(
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      _refreshAllContacts(
        client: client,
        matrixLocalizations: matrixLocalizations,
      );
    });
    contactsManager.initialSynchronizeContacts(
      isAvailableSupportPhonebookContacts: PlatformInfos.isMobile &&
          contactsPermissionStatus == PermissionStatus.granted,
    );
  }

  void _listenContactsDataChange({
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    contactsManager.getContactsNotifier().addListener(
          () => _refreshAllContacts(
            client: client,
            matrixLocalizations: matrixLocalizations,
          ),
        );
    contactsManager.getPhonebookContactsNotifier().addListener(
          () => _refreshAllContacts(
            client: client,
            matrixLocalizations: matrixLocalizations,
          ),
        );
  }

  void _refreshAllContacts({
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    final keyword = _debouncer.value;
    if (keyword.isValidMatrixId && keyword.startsWith("@")) {
      if (presentationContactNotifier.isDisposed &&
          presentationPhonebookContactNotifier.isDisposed) {
        return;
      }
      presentationContactNotifier.value = Right(
        PresentationExternalContactSuccess(
          contact: PresentationContact(
            matrixId: keyword,
            displayName: keyword.substring(1),
            type: ContactType.external,
          ),
        ),
      );
      presentationPhonebookContactNotifier.value =
          const Right(GetPhonebookContactsInitial());
      _refreshRecentContacts(
        client: client,
        keyword: keyword.isEmpty ? null : keyword,
        matrixLocalizations: matrixLocalizations,
      );
      return;
    }
    _refreshContacts(keyword);
    _refreshPhoneBookContacts(keyword);
    _refreshRecentContacts(
      client: client,
      keyword: keyword.isEmpty ? null : keyword,
      matrixLocalizations: matrixLocalizations,
    );
  }

  Future<void> _refreshContacts(String keyword) async {
    if (presentationContactNotifier.isDisposed) return;
    presentationContactNotifier.value =
        contactsManager.getContactsNotifier().value.fold(
      (failure) {
        if (failure is GetContactsFailure) {
          return Left(
            GetPresentationContactsFailure(
              keyword: keyword,
            ),
          );
        }

        if (failure is GetContactsIsEmpty) {
          return Left(
            GetPresentationContactsEmpty(
              keyword: keyword,
            ),
          );
        }
        return Left(failure);
      },
      (success) {
        if (success is GetContactsSuccess) {
          final filteredContacts = success.contacts
              .searchContacts(keyword)
              .expand((contact) => contact.toPresentationContacts())
              .toList();
          if (filteredContacts.isEmpty) {
            return Left(
              GetPresentationContactsEmpty(
                keyword: keyword,
              ),
            );
          } else {
            return Right(
              GetPresentationContactsSuccess(
                contacts: filteredContacts,
                keyword: keyword,
              ),
            );
          }
        }
        return Right(success);
      },
    );
  }

  Future<void> _refreshPhoneBookContacts(String keyword) async {
    if (presentationPhonebookContactNotifier.isDisposed) return;
    presentationPhonebookContactNotifier.value =
        contactsManager.getPhonebookContactsNotifier().value.fold(
      (failure) {
        if (failure is GetPhonebookContactsFailure) {
          return Left(
            GetPresentationContactsFailure(
              keyword: keyword,
            ),
          );
        }

        if (failure is GetPhonebookContactsIsEmpty) {
          return Left(
            GetPresentationContactsEmpty(
              keyword: keyword,
            ),
          );
        }
        return Left(failure);
      },
      (success) {
        if (success is GetPhonebookContactsSuccess) {
          final filteredContacts = success.contacts
              .searchContacts(keyword)
              .expand((contact) => contact.toPresentationContacts())
              .toList();
          if (filteredContacts.isEmpty) {
            return Left(
              GetPresentationContactsEmpty(
                keyword: keyword,
              ),
            );
          } else {
            return Right(
              GetPresentationContactsSuccess(
                contacts: filteredContacts,
                keyword: keyword,
              ),
            );
          }
        }
        return Right(success);
      },
    );
  }

  Future<void> _refreshRecentContacts({
    required Client client,
    required MatrixLocalizations matrixLocalizations,
    String? keyword,
  }) async {
    _searchRecentChatInteractor
        .execute(
      keyword: keyword ?? '',
      matrixLocalizations: matrixLocalizations,
      rooms: client.rooms,
    )
        .listen(
      (event) {
        event.map((success) {
          if (success is SearchRecentChatSuccess) {
            final recent = success
                .toPresentation()
                .contacts
                .where((contact) => contact.directChatMatrixID != null)
                .toList();
            if (presentationRecentContactNotifier.isDisposed) return;
            presentationRecentContactNotifier.value = recent
                .take(
                  keyword == null ? _defaultLimitRecentContacts : recent.length,
                )
                .toList();
          }
        });
      },
    );
  }

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void onSelectedContact() {
    searchFocusNode.requestFocus();
    textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textEditingController.text.length,
    );
  }

  void closeSearchBar() {
    textEditingController.clear();
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
  }

  Future<void> _handleRequestContactsPermission() async {
    final currentContactsPermissionStatus =
        await _permissionHandlerService.requestContactsPermissionActions();
    if (currentContactsPermissionStatus == PermissionStatus.granted) {
      warningBannerNotifier.value = WarningContactsBannerState.hide;
    } else {
      if (!contactsManager.isDoNotShowWarningContactsBannerAgain) {
        warningBannerNotifier.value = WarningContactsBannerState.display;
      }
    }
    contactsPermissionStatus = currentContactsPermissionStatus;
  }

  void closeContactsWarningBanner() {
    contactsManager.updateNotShowWarningContactsBannerAgain = true;
    warningBannerNotifier.value = WarningContactsBannerState.notDisplayAgain;
  }

  void goToSettingsForPermissionActions() {
    _permissionHandlerService.goToSettingsForPermissionActions();
  }

  void disposeContactsMixin() {
    textEditingController.clear();
    searchFocusNode.dispose();
    textEditingController.dispose();
    warningBannerNotifier.dispose();
    isSearchModeNotifier.dispose();
    presentationRecentContactNotifier.dispose();
    presentationContactNotifier.dispose();
    presentationPhonebookContactNotifier.dispose();
  }

  @visibleForTesting
  void refreshAllContactsTest({
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    _refreshAllContacts(
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
  }
}
