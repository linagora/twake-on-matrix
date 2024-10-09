import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/pages/search/search_mixin.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:fluffychat/utils/extension/presentation_search_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchContactsAndChatsController with SearchDebouncerMixin, SearchMixin {
  final BuildContext context;

  SearchContactsAndChatsController(this.context);

  static const int _limitPrefetchedRecentChats = 3;

  final SearchRecentChatInteractor _searchRecentChatInteractor =
      getIt.get<SearchRecentChatInteractor>();

  final ContactsManager contactManger = getIt.get<ContactsManager>();

  final recentAndContactsNotifier = ValueNotifier<List<PresentationSearch>>([]);

  final isShowChatsAndContactsNotifier = ValueNotifier(false);

  void toggleShowMore() {
    isShowChatsAndContactsNotifier.toggle();
  }

  MatrixLocalizations get _matrixLocalizations =>
      MatrixLocals(L10n.of(context)!);

  List<Room> get _rooms => Matrix.of(context).client.rooms;

  void init() {
    initializeDebouncer((keyword) {
      _searchChatsFromLocal(keyword: keyword);
    });
    contactManger.initialSynchronizeContacts();
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
        .listen(
      (event) {
        event.map((success) {
          if (success is SearchRecentChatSuccess) {
            recentAndContactsNotifier.value = success.toPresentation().contacts;
          }
        });
      },
    );
  }

  void _searchChatsFromLocal({required String keyword}) {
    if (keyword.isEmpty) {
      return fetchPreSearchChat();
    }
    final tomContacts = contactManger
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
    _searchRecentChatInteractor
        .execute(
      keyword: keyword,
      matrixLocalizations: _matrixLocalizations,
      rooms: _rooms,
    )
        .listen(
      (event) {
        event.map(
          (success) {
            if (success is SearchRecentChatSuccess) {
              recentAndContactsNotifier.value = combineDuplicateContactAndChat(
                recentChat: success.toPresentation().contacts,
                contacts: tomContactPresentationSearchMatched,
              );
            }
          },
        );
      },
    );
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
  }

  void dispose() {
    disposeDebouncer();
    recentAndContactsNotifier.dispose();
  }
}
