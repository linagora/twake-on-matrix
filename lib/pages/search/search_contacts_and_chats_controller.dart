import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/pages/search/search_mixin.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:fluffychat/utils/extension/presentation_search_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' hide Contact;

class SearchContactsAndChatsController
    with SearchDebouncerMixin, SearchMixin, ContactsViewControllerMixin {
  final BuildContext context;

  SearchContactsAndChatsController(this.context);

  static const int _limitPrefetchedRecentChats = 3;

  final SearchRecentChatInteractor _searchRecentChatInteractor = getIt
      .get<SearchRecentChatInteractor>();

  final ContactsManager contactManger = getIt.get<ContactsManager>();

  final recentAndContactsNotifier = ValueNotifier<List<PresentationSearch>>([]);

  final isShowChatsAndContactsNotifier = ValueNotifier(false);

  void toggleShowMore() {
    isShowChatsAndContactsNotifier.toggle();
  }

  MatrixLocalizations get _matrixLocalizations =>
      MatrixLocals(L10n.of(context)!);

  Client get client => Matrix.of(context).client;

  List<Room> get _rooms => client.rooms;

  Future<void> init() async {
    initializeDebouncer((keyword) {
      _searchChatsFromLocal(keyword: keyword);
    });
    initialFetchContacts(
      context: context,
      client: Matrix.of(context).client,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
    );
    fetchPreSearchChat();
  }

  void fetchPreSearchChat() {
    _searchRecentChatInteractor
        .execute(
          keyword: '',
          matrixLocalizations: _matrixLocalizations,
          rooms: _rooms,
          limit: _limitPrefetchedRecentChats,
        )
        .listen((event) {
          event.map((success) {
            if (success is SearchRecentChatSuccess) {
              recentAndContactsNotifier.value = success
                  .toPresentation()
                  .contacts;
            }
          });
        });
  }

  List<PresentationSearch> contactPresentationSearchMatchedOnMobile({
    required String keyword,
  }) {
    final tomContacts =
        contactManger
            .getContactsNotifier()
            .value
            .getSuccessOrNull<GetContactsSuccess>()
            ?.contacts ??
        [];

    final phoneBookContacts = _tryToGetPhonebookContacts();
    final tomPresentationSearchContacts = tomContacts
        .expand((contact) => contact.toPresentationContacts())
        .toList();

    final phoneBookPresentationSearchContacts = phoneBookContacts
        .expand((contact) => contact.toPresentationContacts())
        .toList();

    final phoneBookPresentationSearchMatched =
        phoneBookPresentationSearchContacts
            .expand((contact) => contact.toPresentationSearch())
            .where((contact) {
              final matrixId = (contact as ContactPresentationSearch).matrixId;
              return matrixId != null &&
                  matrixId.isNotEmpty &&
                  contact.doesMatchKeyword(keyword);
            })
            .toList();
    final tomContactPresentationSearchMatched = tomPresentationSearchContacts
        .expand((contact) => contact.toPresentationSearch())
        .where((contact) => contact.doesMatchKeyword(keyword))
        .toList();

    return combineDuplicateContactAndChat(
      recentChat: tomContactPresentationSearchMatched,
      contacts: phoneBookPresentationSearchMatched,
    );
  }

  List<Contact> _tryToGetPhonebookContacts() {
    final phoneBookContacts =
        contactManger
            .getPhonebookContactsNotifier()
            .value
            .getSuccessOrNull<GetPhonebookContactsSuccess>()
            ?.contacts ??
        contactManger
            .getPhonebookContactsNotifier()
            .value
            .getFailureOrNull<LookUpPhonebookContactPartialFailed>()
            ?.contacts ??
        contactManger
            .getPhonebookContactsNotifier()
            .value
            .getFailureOrNull<GetPhonebookContactsFailure>()
            ?.contacts ??
        contactManger
            .getPhonebookContactsNotifier()
            .value
            .getFailureOrNull<RequestTokenFailure>()
            ?.contacts ??
        contactManger
            .getPhonebookContactsNotifier()
            .value
            .getFailureOrNull<RegisterTokenFailure>()
            ?.contacts ??
        [];
    return phoneBookContacts;
  }

  List<PresentationSearch> contactPresentationSearchMatchedOnWeb({
    required String keyword,
  }) {
    final tomContacts =
        contactManger
            .getContactsNotifier()
            .value
            .getSuccessOrNull<GetContactsSuccess>()
            ?.contacts ??
        [];

    final tomPresentationSearchContacts = tomContacts
        .expand((contact) => contact.toPresentationContacts())
        .toList();

    final tomContactPresentationSearchMatched = tomPresentationSearchContacts
        .expand((contact) => contact.toPresentationSearch())
        .where((contact) => contact.doesMatchKeyword(keyword))
        .toList();

    return combineDuplicateContactAndChat(
      recentChat: tomContactPresentationSearchMatched,
      contacts: [],
    );
  }

  void _searchChatsFromLocal({required String keyword}) {
    if (keyword.isEmpty) {
      return fetchPreSearchChat();
    }

    _searchRecentChatInteractor
        .execute(
          keyword: keyword,
          matrixLocalizations: _matrixLocalizations,
          rooms: _rooms,
        )
        .listen((event) {
          event.map((success) {
            if (success is SearchRecentChatSuccess) {
              recentAndContactsNotifier.value = combineDuplicateContactAndChat(
                recentChat: success.toPresentation().contacts,
                contacts: PlatformInfos.isMobile
                    ? contactPresentationSearchMatchedOnMobile(keyword: keyword)
                    : contactPresentationSearchMatchedOnWeb(keyword: keyword),
              );
            }
          });
        });
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
  }

  void dispose() {
    disposeDebouncer();
    recentAndContactsNotifier.dispose();
  }
}
