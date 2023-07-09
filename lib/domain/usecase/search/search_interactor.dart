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
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';

class SearchContactsAndRecentChatInteractor {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  SearchContactsAndRecentChatInteractor();

  Stream<Either<Failure, GetContactAndRecentChatSuccess>> execute({
    required BuildContext context,
    required String keyword,
    int? limitContacts,
    int? limitRecentChats,
    bool enableSearch = false
  }) async* {
    try {
      if (enableSearch) {
        final recentChat = await _searchRecentChat(context, keyword);
        final contacts = await contactRepository.searchContact(query: ContactQuery(keyword: keyword), limit: limitContacts);

        final presentationSearches = _comparePresentationSearches(
          recentChat.toPresentationSearchList(context),
          contacts.expand((contact) => contact.toPresentationContacts()).toList().toPresentationSearchList()
        );
        yield Right(GetContactAndRecentChatSuccess(presentationSearches: presentationSearches));
      } else {
        final rooms = await _getRecentChat(context, limitRecentChats: limitRecentChats);
        yield Right(GetContactAndRecentChatSuccess(presentationSearches: rooms.toPresentationSearchList(context)));
      }
    } catch (e) {
      yield Left(GetContactAndRecentChatFailed(exception: e));
    }
  }

  Future<List<Room>> _getRecentChat(BuildContext context, {int? limitRecentChats}) async {
    return Matrix.of(context).client.rooms.where((room) => !room.isSpace && !room.isStoryRoom)
      .where((room) => room.isShowInChatList())
      .take(limitRecentChats ?? 0)
      .toList();
  }

  Future<List<Room>> _searchRecentChat(BuildContext context, String keyword) async {
    return Matrix.of(context).client.rooms.where((room) => !room.isSpace && !room.isStoryRoom)
      .where((room) => room.isShowInChatList())
      .where((room) =>
        room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)!))
        .toLowerCase()
        .contains(keyword.toLowerCase())
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