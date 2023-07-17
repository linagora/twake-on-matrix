import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/room/room_list_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:matrix/matrix.dart';

class SearchContactsAndRecentChatInteractor {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  SearchContactsAndRecentChatInteractor();

  Stream<Either<Failure, GetContactAndRecentChatSuccess>> execute({
    required List<Room> rooms,
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limitContacts,
    int? limitRecentChats,
  }) async* {
    try {
      if (keyword.isNotEmpty) {
        final recentChat = await _searchRecentChat(rooms: rooms, matrixLocalizations: matrixLocalizations, keyword: keyword);
        final contacts = await contactRepository.searchContact(query: ContactQuery(keyword: keyword), limit: limitContacts);

        final presentationSearches = _comparePresentationSearches(
          recentChat.toSearchList(matrixLocalizations),
          contacts.expand((contact) => contact.toSearch())
            .where((contact) => _compareDisplayNameWithKeyword(contact, keyword))
            .toList()
        );
        yield Right(GetContactAndRecentChatSuccess(search: presentationSearches));
      } else {
        final recentChat = await _getRecentChat(rooms: rooms, limitRecentChats: limitRecentChats);
        yield Right(GetContactAndRecentChatSuccess(search: recentChat.toSearchList(matrixLocalizations)));
      }
    } catch (e) {
      yield Left(GetContactAndRecentChatFailed(exception: e));
    }
  }

  bool _compareDisplayNameWithKeyword(SearchModel search, String keyword) {
    if (search.displayName != null) {
      return search.displayName!.toLowerCase().contains(keyword.toLowerCase());
    } else {
      return false;
    }
  }

  Future<List<Room>> _getRecentChat({
    required List<Room> rooms,
    int? limitRecentChats
  }) async {
    return rooms.where((room) => room.isNotSpaceAndStoryRoom())
      .where((room) => room.isShowInChatList())
      .take(limitRecentChats ?? 0)
      .toList();
  }

  Future<List<Room>> _searchRecentChat({
    required List<Room> rooms,
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
  }) async {
    return rooms.where((room) => room.isNotSpaceAndStoryRoom())
      .where((room) =>
        room.getLocalizedDisplayname(matrixLocalizations)
          .toLowerCase()
          .contains(keyword.toLowerCase())
      ).toList();
  }

  List<SearchModel> _comparePresentationSearches(List<SearchModel> recentChat, List<SearchModel> contacts) {
    final isDuplicateElement = contacts.where((contact) {
      return recentChat.any((recentChat) => recentChat.directChatMatrixID == contact.directChatMatrixID);
    }).toList();
    if (isDuplicateElement.isNotEmpty) {
      final presentationSearches = recentChat + contacts;
      presentationSearches.removeWhere((contact) => isDuplicateElement.contains(contact));
      return presentationSearches;
    } else {
      return recentChat + contacts;
    }
  }
}