import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/extensions/contact/presentation_contact_list_extension.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:fluffychat/presentation/extensions/room_list_extension.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
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
    bool enableSearch = false
  }) async* {
    try {
      if (enableSearch) {
        final recentChat = await _searchRecentChat(rooms: rooms, matrixLocalizations: matrixLocalizations, keyword: keyword);
        final contacts = await contactRepository.searchContact(query: ContactQuery(keyword: keyword), limit: limitContacts);

        final presentationSearches = _comparePresentationSearches(
          recentChat.toPresentationSearchList(matrixLocalizations),
          contacts.expand((contact) => contact.toPresentationContacts())
            .toList()
            .toPresentationSearchList()
        );
        yield Right(GetContactAndRecentChatSuccess(presentationSearches: presentationSearches));
      } else {
        final recentChat = await _getRecentChat(rooms: rooms, limitRecentChats: limitRecentChats);
        yield Right(GetContactAndRecentChatSuccess(presentationSearches: recentChat.toPresentationSearchList(matrixLocalizations)));
      }
    } catch (e) {
      yield Left(GetContactAndRecentChatFailed(exception: e));
    }
  }

  Future<List<Room>> _getRecentChat({
    required List<Room> rooms,
    int? limitRecentChats
  }) async {
    return rooms.where((room) => !room.isSpace && !room.isStoryRoom)
      .where((room) => room.isShowInChatList())
      .take(limitRecentChats ?? 0)
      .toList();
  }

  Future<List<Room>> _searchRecentChat({
    required List<Room> rooms,
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
  }) async {
    return rooms.where((room) => !room.isSpace && !room.isStoryRoom)
      .where((room) =>
        room.getLocalizedDisplayname(matrixLocalizations)
        .toLowerCase()
        .contains(keyword.toLowerCase())
        && room.isShowInChatList()
      ).toList();
  }

  List<PresentationSearch> _comparePresentationSearches(List<PresentationSearch> recentChat, List<PresentationSearch> contacts) {
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