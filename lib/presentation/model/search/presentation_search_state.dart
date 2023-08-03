import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

class GetContactAndRecentChatPresentation extends Success {
  final List<PresentationSearch> searchResult;
  final int contactsOffset;
  final bool shouldLoadMoreContacts;
  final String keyword;

  const GetContactAndRecentChatPresentation({
    required this.searchResult,
    required this.contactsOffset,
    required this.shouldLoadMoreContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [searchResult, contactsOffset, shouldLoadMoreContacts, keyword];
}