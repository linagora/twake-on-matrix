import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/search/search_state.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/controllers/contacts_controller.dart';
import 'package:twake_chat/presentation/extensions/contact/unified_contact_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/pages/search/search_debouncer_mixin.dart';
import 'package:twake_chat/pages/search/search_mixin.dart';
import 'package:twake_chat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_search_state_extension.dart';
import 'package:twake_chat/utils/extension/presentation_search_extension.dart';
import 'package:twake_chat/utils/extension/value_notifier_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' hide Contact;

class SearchContactsAndChatsController
    with SearchDebouncerMixin, SearchMixin, ContactsViewControllerMixin {
  final BuildContext context;

  SearchContactsAndChatsController(this.context);

  static const int _limitPrefetchedRecentChats = 3;

  final SearchRecentChatInteractor _searchRecentChatInteractor = getIt
      .get<SearchRecentChatInteractor>();

  List<UnifiedContact> _storeContacts() {
    try {
      return ProviderScope.containerOf(
            context,
            listen: false,
          ).read(contactsControllerProvider).asData?.value ??
          const <UnifiedContact>[];
    } catch (_) {
      return const <UnifiedContact>[];
    }
  }

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
    final tomPresentationSearchContacts = _storeContacts()
        .where((contact) => contact.isAddressBookContact)
        .map((contact) => contact.toPresentationContact())
        .toList();

    final phoneBookPresentationSearchContacts = _storeContacts()
        .where(
          (contact) => contact.sources.any(
            (source) => source.kind == ContactSourceKind.phonebook,
          ),
        )
        .map((contact) => contact.toPresentationContact())
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

  List<PresentationSearch> contactPresentationSearchMatchedOnWeb({
    required String keyword,
  }) {
    final tomPresentationSearchContacts = _storeContacts()
        .where((contact) => contact.isAddressBookContact)
        .map((contact) => contact.toPresentationContact())
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
