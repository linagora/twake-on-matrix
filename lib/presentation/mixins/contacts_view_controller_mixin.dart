import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/contact/get_contacts_state.dart';
import 'package:twake_chat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:twake_chat/domain/app_state/search/search_state.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact_manager/contacts_manager.dart';
import 'package:twake_chat/domain/model/contact/contact.dart'
    show ThirdPartyIdType;
import 'package:twake_chat/domain/model/contact/contact_status.dart';
import 'package:twake_chat/domain/model/contact/contact_type.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/pages/contacts_tab/controllers/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:twake_chat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:twake_chat/presentation/extensions/value_notifier_custom.dart';
import 'package:twake_chat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:twake_chat/presentation/model/contact/get_presentation_contacts_success.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_success.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:twake_chat/utils/extension/presentation_search_extension.dart';
import 'package:twake_chat/utils/permission_dialog.dart';
import 'package:twake_chat/utils/permission_service.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

mixin class ContactsViewControllerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  static const _defaultLimitRecentContacts = 6;

  final TextEditingController textEditingController = TextEditingController();

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  final SearchRecentChatInteractor _searchRecentChatInteractor = getIt
      .get<SearchRecentChatInteractor>();

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

  /// Current snapshot of the unified store, refreshed from the Riverpod
  /// controller (single source of truth for the contacts list).
  List<UnifiedContact> _unifiedContacts = const <UnifiedContact>[];

  ProviderSubscription<AsyncValue<List<UnifiedContact>>>?
  _unifiedContactsSubscription;

  /// Returns the Riverpod container when the widget is under a
  /// `ProviderScope`. Some legacy/unit-test contexts are not, so the mixin
  /// degrades gracefully instead of throwing.
  ProviderContainer? _tryContainer(BuildContext context) {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshUnifiedContacts(BuildContext context) async {
    final container = _tryContainer(context);
    if (container == null) return;
    await container.read(contactSyncServiceProvider).refresh();
  }

  void _startListeningUnifiedContacts({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    final container = _tryContainer(context);
    if (container == null) return;
    _unifiedContactsSubscription?.close();
    _unifiedContactsSubscription = container.listen(
      contactsControllerProvider,
      (previous, next) {
        next.whenData((contacts) {
          _unifiedContacts = contacts;
          _refreshAllContacts(
            context: context,
            client: client,
            matrixLocalizations: matrixLocalizations,
          );
        });
      },
      fireImmediately: true,
    );
  }

  PermissionStatus? contactsPermissionStatus;

  bool _canReadPhonebookContacts(PermissionStatus? status) =>
      status == PermissionStatus.granted || status == PermissionStatus.limited;

  bool get enablePhonebookLookup => true;

  /// Whether contacts without a Matrix ID are listed: they can only be
  /// invited, which the homeserver may disable.
  bool get isInvitationEnabled => false;

  Future<void> _initPhonebookPermission(BuildContext context) async {
    if (!enablePhonebookLookup) {
      warningBannerNotifier.value = WarningContactsBannerState.hide;
      return;
    }

    if (PlatformInfos.isMobile &&
        !contactsManager.isDoNotShowWarningContactsDialogAgain) {
      await displayContactPermissionDialog(context);
    } else {
      await _initWarningBanner();
    }
  }

  bool get phoneBookFilterSuccess => presentationPhonebookContactNotifier.value
      .fold((_) => false, (success) => success is GetPhonebookContactsSuccess);

  bool get hasVisibleContacts =>
      presentationContactNotifier.value.fold(
        (_) => false,
        (success) =>
            (success is PresentationContactsSuccess &&
                success.contacts.isNotEmpty) ||
            success is PresentationExternalContactSuccess,
      ) ||
      presentationPhonebookContactNotifier.value.fold(
        (_) => false,
        (success) =>
            success is PresentationContactsSuccess &&
            success.contacts.isNotEmpty,
      ) ||
      presentationRecentContactNotifier.value.isNotEmpty;

  bool get isLoadingContacts =>
      presentationContactNotifier.value.fold(
        (_) => false,
        (success) => success is ContactsLoading,
      ) ||
      presentationPhonebookContactNotifier.value.fold(
        (_) => false,
        (success) => success is GetPhonebookContactsLoading,
      );

  bool get isWaitingContacts =>
      isLoadingContacts ||
      presentationContactNotifier.value.fold(
        (_) => false,
        (success) => success is ContactsInitial,
      ) ||
      presentationPhonebookContactNotifier.value.fold(
        (_) => false,
        (success) => success is GetPhonebookContactsInitial,
      );

  /// Whether recent contacts (DMs found by the SDK) are mixed into the
  /// contacts list. The Contacts page must reflect the ToM Address Book only,
  /// so it overrides this to `false` (see issue #3097). Views like DM/group
  /// creation keep recents enabled.
  bool get enableRecentContacts => true;

  Future displayContactPermissionDialog(BuildContext context) async {
    if (!enablePhonebookLookup) {
      return;
    }

    final fetchContactsPermissionStatus =
        await _permissionHandlerService.contactsPermissionStatus;

    contactsPermissionStatus = fetchContactsPermissionStatus;

    if (PlatformInfos.isMobile &&
        !_canReadPhonebookContacts(fetchContactsPermissionStatus)) {
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
              await _handleRequestContactsPermission(
                context: context,
                client: Matrix.of(context).client,
              );
            },
          );
        },
      );
    }
  }

  void _handleDenyPermissionDialog() {
    warningBannerNotifier.value = WarningContactsBannerState.display;
    contactsManager.updateNotShowWarningContactsDialogAgain(true);
  }

  Future<void> _initWarningBanner() async {
    if (!enablePhonebookLookup) {
      warningBannerNotifier.value = WarningContactsBannerState.hide;
      return;
    }

    if (!PlatformInfos.isMobile) {
      return;
    }
    final currentContactPermission =
        await _permissionHandlerService.contactsPermissionStatus;
    Logs().i(
      'ContactsViewControllerMixin::_initWarningBanner: Contact Permission $currentContactPermission',
    );

    if (_canReadPhonebookContacts(currentContactPermission)) {
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

  Future<void> handleDidChangeAppLifecycleState(
    AppLifecycleState state, {
    required BuildContext context,
    required Client client,
  }) async {
    if (!enablePhonebookLookup || !PlatformInfos.isMobile) {
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
          _canReadPhonebookContacts(currentContactPermission)) {
        contactsPermissionStatus = currentContactPermission;
        warningBannerNotifier.value = WarningContactsBannerState.hide;
        unawaited(_refreshUnifiedContacts(context));
        return;
      }
    }
  }

  void initialFetchContacts({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
    bool forceRun = false,
  }) async {
    await _initPhonebookPermission(context);
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

    if (client.userID == null) {
      return;
    }
    await _refreshUnifiedContacts(context);
  }

  void synchronizeContactsOnContactTab({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) async {
    await _initPhonebookPermission(context);
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

    if (client.userID == null) {
      return;
    }
    await _refreshUnifiedContacts(context);
  }

  Future<void> retrySynchronizeContactsOnContactTab({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) async {
    try {
      await _initPhonebookPermission(context);

      if (client.userID == null) {
        return;
      }

      _refreshAllContacts(
        context: context,
        client: client,
        matrixLocalizations: matrixLocalizations,
      );
      await _refreshUnifiedContacts(context);
    } catch (error, stackTrace) {
      Logs().e(
        'ContactsViewControllerMixin::retrySynchronizeContactsOnContactTab',
        error,
        stackTrace,
      );
    }
  }

  void _listenContactsDataChange({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    _startListeningUnifiedContacts(
      context: context,
      client: client,
      matrixLocalizations: matrixLocalizations,
    );
  }

  void _refreshAllContacts({
    required BuildContext context,
    required Client client,
    required MatrixLocalizations matrixLocalizations,
  }) {
    _unifiedContacts =
        _tryContainer(
          context,
        )?.read(contactsControllerProvider).asData?.value ??
        _unifiedContacts;
    final keyword = _debouncer.value.trim();
    _refreshContacts(keyword);
    _refreshPhoneBookContacts(keyword);
    if (enableRecentContacts) {
      _refreshRecentContacts(
        context: context,
        client: client,
        keyword: keyword.isEmpty ? null : keyword,
        matrixLocalizations: matrixLocalizations,
      );
    }
  }

  Future<void> _refreshContacts(String keyword) async {
    if (presentationContactNotifier.isDisposed) return;

    final externalContactState = _checkExternalContact(keyword);
    final tomContacts = _hideInvitationOnlyContacts(
      _tomContactsForTab(keyword).map(_toPresentationContact).toList(),
    );

    presentationContactNotifier.value = tomContacts.isEmpty
        ? (externalContactState ??
              Left(GetPresentationContactsEmpty(keyword: keyword)))
        : Right(
            GetPresentationContactsSuccess(
              contacts: tomContacts,
              keyword: keyword,
            ),
          );
  }

  Either<Failure, Success>? _checkExternalContact(String keyword) {
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
    }
    return null;
  }

  Future<void> _refreshPhoneBookContacts(String keyword) async {
    if (presentationPhonebookContactNotifier.isDisposed) return;

    final phonebookContacts = _hideInvitationOnlyContacts(
      _phonebookContactsForTab(keyword).map(_toPresentationContact).toList(),
    );

    presentationPhonebookContactNotifier.value = phonebookContacts.isEmpty
        ? Left(GetPresentationContactsEmpty(keyword: keyword))
        : Right(
            GetPresentationContactsSuccess(
              contacts: phonebookContacts,
              keyword: keyword,
            ),
          );
  }

  PresentationContact _toPresentationContact(UnifiedContact contact) {
    return PresentationContact(
      id: contact.matrixId,
      displayName: contact.resolvedDisplayName,
      matrixId: contact.matrixId,
      status: contact.active ? ContactStatus.active : ContactStatus.inactive,
      emails: contact.emails
          .map(
            (email) => PresentationEmail(
              email: email,
              thirdPartyId: email,
              thirdPartyIdType: ThirdPartyIdType.email,
              matrixId: contact.matrixId,
            ),
          )
          .toSet(),
      phoneNumbers: contact.phones
          .map(
            (phone) => PresentationPhoneNumber(
              phoneNumber: phone,
              thirdPartyId: phone,
              thirdPartyIdType: ThirdPartyIdType.msisdn,
              matrixId: contact.matrixId,
            ),
          )
          .toSet(),
    );
  }

  bool _hasPhonebookSource(UnifiedContact contact) => contact.sources.any(
    (source) => source.kind == ContactSourceKind.phonebook,
  );

  bool _hasAddressBookSource(UnifiedContact contact) => contact.sources.any(
    (source) =>
        source.kind == ContactSourceKind.tomAddressBook ||
        source.kind == ContactSourceKind.tomUserInfo ||
        source.kind == ContactSourceKind.manual,
  );

  List<UnifiedContact> _tomContactsForTab(String keyword) => _unifiedContacts
      .where((contact) => _hasAddressBookSource(contact))
      .where((contact) => !_hasPhonebookSource(contact))
      .where((contact) => _matchesUnifiedKeyword(contact, keyword))
      .toList();

  List<UnifiedContact> _phonebookContactsForTab(String keyword) =>
      _unifiedContacts
          .where(_hasPhonebookSource)
          .where((contact) => _matchesUnifiedKeyword(contact, keyword))
          .toList();

  bool _matchesUnifiedKeyword(UnifiedContact contact, String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(normalized);
    return contains(contact.resolvedDisplayName) ||
        contains(contact.matrixId) ||
        contact.emails.any(contains) ||
        contact.phones.any(contains);
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
        .listen((event) {
          event.map((success) {
            if (success is SearchRecentChatSuccess) {
              final recent = success
                  .toPresentation()
                  .contacts
                  .where((contact) => contact.directChatMatrixID != null)
                  .toList();

              final tomPresentationSearchContacts = _tomContactsForTab(
                '',
              ).map(_toPresentationContact).toList();
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
        });
  }

  List<PresentationSearch> handleSearchRecentContacts({
    required List<PresentationSearch> contacts,
    required List<PresentationSearch> recentChat,
    required String keyword,
  }) {
    if (keyword.isEmpty) {
      return _getRecentContactsExcludingContacts(
        recentChat: recentChat,
        contacts: contacts,
      ).take(_defaultLimitRecentContacts).toList();
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
    final List<PresentationSearch> filteredRecentChat = recentChat.where((
      chat,
    ) {
      return !contactIds.contains(chat.directChatMatrixID);
    }).toList();

    return filteredRecentChat;
  }

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void onSelectedContact() {
    textEditingController.clear();
    searchFocusNode.requestFocus();
  }

  void closeSearchBar() {
    textEditingController.clear();
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
  }

  Future<void> _handleRequestContactsPermission({
    required BuildContext context,
    required Client client,
  }) async {
    if (!enablePhonebookLookup) {
      return;
    }

    final currentContactsPermissionStatus = await _permissionHandlerService
        .requestContactsPermissionActions();
    if (_canReadPhonebookContacts(currentContactsPermissionStatus)) {
      unawaited(_refreshUnifiedContacts(context));
      warningBannerNotifier.value = WarningContactsBannerState.hide;
    } else {
      contactsManager.updateNotShowWarningContactsDialogAgain(true);

      if (!contactsManager.isDoNotShowWarningContactsBannerAgain) {
        warningBannerNotifier.value = WarningContactsBannerState.display;
      }
    }
    contactsPermissionStatus = currentContactsPermissionStatus;
  }

  void closeContactsWarningBanner() {
    contactsManager.updateNotShowWarningContactsBannerAgain(true);
    warningBannerNotifier.value = WarningContactsBannerState.notDisplayAgain;
  }

  void goToSettingsForPermissionActions() {
    _permissionHandlerService.goToSettingsForPermissionActions();
  }

  List<PresentationContact> _hideInvitationOnlyContacts(
    List<PresentationContact> contacts,
  ) {
    if (isInvitationEnabled) return contacts;
    return contacts
        .where((contact) => (contact.matrixId ?? '').isNotEmpty)
        .toList();
  }

  void disposeContactsMixin() {
    _unifiedContactsSubscription?.close();
    _debouncer.cancel();
    textEditingController.clear();
    searchFocusNode.dispose();
    textEditingController.dispose();
    warningBannerNotifier.dispose();
    isSearchModeNotifier.dispose();
    presentationRecentContactNotifier.dispose();
    presentationContactNotifier.dispose();
    presentationPhonebookContactNotifier.dispose();
  }

  void refreshAllContacts({
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

  /// Test seam: inject the unified store snapshot without a `ProviderScope`.
  @visibleForTesting
  void setUnifiedContactsForTest(List<UnifiedContact> contacts) {
    _unifiedContacts = contacts;
  }
}
