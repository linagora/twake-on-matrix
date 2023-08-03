import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/extensions/search/search_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

class GetContactAndRecentChatInitial extends Initial {

  const GetContactAndRecentChatInitial() : super();

  @override
  List<Object?> get props => [];
}

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

extension GetContactAndRecentChatSuccessToPresentationExtension on GetContactAndRecentChatSuccess {
  GetContactAndRecentChatPresentation toPresentation({ GetContactAndRecentChatPresentation? oldPresentation }) {
    return GetContactAndRecentChatPresentation(
      searchResult: (oldPresentation?.searchResult ?? []) + searchResult.map((item) => item.toPresentationSearch()).toList(),
      contactsOffset: contactsOffset,
      shouldLoadMoreContacts: shouldLoadMoreContacts,
      keyword: keyword,
    );
  } 
}

class GetContactAndRecentChatSuccess extends Success {
  final List<SearchModel> searchResult;
  final int contactsOffset;
  final bool shouldLoadMoreContacts;
  final String keyword;

  const GetContactAndRecentChatSuccess({
    required this.searchResult,
    required this.contactsOffset,
    required this.shouldLoadMoreContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [searchResult, contactsOffset, shouldLoadMoreContacts, keyword];
}

class GetContactAndRecentChatFailed extends Failure {

  final dynamic exception;

  const GetContactAndRecentChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];

}