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
import 'package:fluffychat/utils/extension/presentation_search_extension.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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

  PermissionStatus? contactsPermissionStatus;

  Future displayContactPermissionDialog(BuildContext context) async {
    final fetchContactsPermissionStatus =
        await _permissionHandlerService.contactsPermissionStatus;

    contactsPermissionStatus = fetchContactsPermissionStatus;

    if (PlatformInfos.isMobile && !fetchContactsPermissionStatus.isGranted) {
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (dialogContext) {
          return PermissionDialog(
            icon: const Icon(Icons.contact_page_outlined),
            permission: Permission.contacts,
            explainTextRequestPermission: Text(
              L10n.of(context)!.explainPermissionToAccessContacts,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onRefuseTap: _handleDenyPermissionDialog,
            onAcceptButton: () async {
              Navigator.of(dialogContext).pop();
              await _handleRequestContactsPermission();
            },
          );
        },
      );
    }
  }

  void _handleDenyPermissionDialog() {
    warningBannerNotifier.value = WarningContactsBannerState.display;
    contactsManager.updateNotShowWarningContactsDialogAgain = true;
  }

  Future<void> _initWarningBanner() async {
    if (!PlatformInfos.isMobile) {
      return;
    }
    final currentContactPermission =
        await _permissionHandlerService.contactsPermissionStatus;
    Logs().i(
      'ContactsViewControllerMixin::_initWarningBanner: Contact Permission $currentContactPermission',
    );

    if (currentContactPermission.isGranted) {
      contactsPermissionStatus = currentContactPermission;
      warningBannerNotifier.value = WarningContactsBannerState.hide;
      return;
    }

    if (!contactsManager.isDoNotShowWarningContactsBannerAgain &&
        contactsManager.isDoNotShowWarningContactsDialogAgain) {
      warningBannerNotifier.value = WarningContactsBannerState.display;
      return;
    }
  }

  Future<void> handleDidChangeAppLifecycleState(AppLifecycleState state) async {
    if (!PlatformInfos.isMobile) {
      return;
    }
    Logs().i(
      'ContactsViewControllerMixin::handleDidChangeAppLifecycleState: $state',
    );

    if (state == AppLifecycleState.resumed) {
      final currentContactPermission =
          await _permissionHandlerService.contactsPermissionStatus;

      Logs().i(
        'ContactsViewControllerMixin::handleDidChangeAppLifecycleState: Contact Permission $currentContactPermission',
      );

      if (currentContactPermission != contactsPermissionStatus &&
          currentContactPermission.isDenied) {
        if (!contactsManager.isDoNotShowWarningContactsBannerAgain) {
          warningBannerNotifier.value = WarningContactsBannerState.display;
        }
        contactsPermissionStatus = currentContactPermission;
        return;
      }

      if (currentContactPermission != contactsPermissionStatus &&
          currentContactPermission.isGranted) {
        contactsPermissionStatus = currentContactPermission;
        warningBannerNotifier.value = WarningContactsBannerState.hide;
        contactsManager.refreshPhonebookContacts();
        return;
      }
    }
  }

  void initialFetchContacts({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) async {
    if (PlatformInfos.isMobile &&
        !contactsManager.isDoNotShowWarningContactsDialogAgain) {
      await displayContactPermissionDialog(context);
    } else {
      await _initWarningBanner();
    }
    _refreshAllContacts(
      context: context,
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
    _listenContactsDataChange(
      context: context,
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      _refreshAllContacts(
        context: context,
        client: client,
        matrixLocalizations: matrixLocalizations,
      );
    });
    contactsManager.initialSynchronizeContacts(
      isAvailableSupportPhonebookContacts: PlatformInfos.isMobile &&
          contactsPermissionStatus != null &&
          contactsPermissionStatus == PermissionStatus.granted,
    );
  }

  void _listenContactsDataChange({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    contactsManager.getContactsNotifier().addListener(
          () => _refreshAllContacts(
            context: context,
            client: client,
            matrixLocalizations: matrixLocalizations,
          ),
        );
    contactsManager.getPhonebookContactsNotifier().addListener(
          () => _refreshAllContacts(
            context: context,
            client: client,
            matrixLocalizations: matrixLocalizations,
          ),
        );
  }

  void _refreshAllContacts({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    final keyword = _debouncer.value;
    _refreshContacts(keyword);
    _refreshPhoneBookContacts(keyword);
    _refreshRecentContacts(
      context: context,
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
          return _handleSearchExternalContact(
            keyword,
            otherResult: Left(
              GetPresentationContactsFailure(
                keyword: keyword,
              ),
            ),
          );
        }

        if (failure is GetContactsIsEmpty) {
          return _handleSearchExternalContact(
            keyword,
            otherResult: Left(
              GetPresentationContactsEmpty(
                keyword: keyword,
              ),
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
            if (presentationRecentContactNotifier.value.isNotEmpty) {
              return Left(
                GetPresentationContactsEmpty(
                  keyword: keyword,
                ),
              );
            }
            if (keyword.isValidMatrixId && keyword.startsWith("@")) {
              return Right(
                PresentationExternalContactSuccess(
                  contact: PresentationContact(
                    matrixId: keyword,
                    displayName: keyword.substring(1),
                    type: ContactType.external,
                  ),
                ),
              );
            } else {
              return Left(
                GetPresentationContactsEmpty(
                  keyword: keyword,
                ),
              );
            }
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
          return _handleSearchExternalContact(
            keyword,
            otherResult: Left(
              GetPresentationContactsFailure(
                keyword: keyword,
              ),
            ),
          );
        }

        if (failure is GetPhonebookContactsIsEmpty) {
          return _handleSearchExternalContact(
            keyword,
            otherResult: Left(
              GetPresentationContactsEmpty(
                keyword: keyword,
              ),
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

  Either<Failure, Success> _handleSearchExternalContact(
    String keyword, {
    required Either<Failure, Success> otherResult,
  }) {
    if (keyword.isValidMatrixId && keyword.startsWith("@")) {
      return Right(
        PresentationExternalContactSuccess(
          contact: PresentationContact(
            matrixId: keyword,
            displayName: keyword.substring(1),
            type: ContactType.external,
          ),
        ),
      );
    } else {
      return otherResult;
    }
  }

  Future<void> _refreshRecentContacts({
    required BuildContext context,
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

            final tomContacts = contactsManager
                    .getContactsNotifier()
                    .value
                    .getSuccessOrNull<GetContactsSuccess>()
                    ?.contacts ??
                [];
            final tomPresentationSearchContacts = tomContacts
                .expand((contact) => contact.toPresentationContacts())
                .toList();
            final tomContactPresentationSearchMatched =
                tomPresentationSearchContacts
                    .expand((contact) => contact.toPresentationSearch())
                    .where(
                      (contact) => contact.doesMatchKeyword(success.keyword),
                    )
                    .toList();
            if (presentationRecentContactNotifier.isDisposed) return;

            presentationRecentContactNotifier.value =
                handleSearchRecentContacts(
              contacts: tomContactPresentationSearchMatched,
              recentChat: recent,
              keyword: success.keyword,
            );
          }
        });
      },
    );
  }

  List<PresentationSearch> handleSearchRecentContacts({
    required List<PresentationSearch> contacts,
    required List<PresentationSearch> recentChat,
    required String keyword,
  }) {
    if (keyword.isEmpty) {
      return recentChat.take(_defaultLimitRecentContacts).toList();
    } else {
      return _getRecentContactsExcludingContacts(
        recentChat: recentChat,
        contacts: contacts,
      );
    }
  }

  List<PresentationSearch> _getRecentContactsExcludingContacts({
    required List<PresentationSearch> contacts,
    required List<PresentationSearch> recentChat,
  }) {
    final contactIds = contacts.map((contact) => contact.id).toSet();
    final List<PresentationSearch> filteredRecentChat =
        recentChat.where((chat) {
      return !contactIds.contains(
        chat.directChatMatrixID,
      );
    }).toList();

    return filteredRecentChat;
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
      contactsManager.refreshPhonebookContacts();
      warningBannerNotifier.value = WarningContactsBannerState.hide;
    } else {
      contactsManager.updateNotShowWarningContactsDialogAgain = true;

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
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    _refreshAllContacts(
      context: context,
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
  }
}
