import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:matrix/matrix.dart';

class SearchContactsInteractor {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  SearchContactsInteractor();

  Stream<Either<Failure, GetContactAndRecentChatSuccess>> execute({
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    required int offset,
    required int limit,
  }) async* {
    try {
      final contacts = await contactRepository.searchContact(
        query: ContactQuery(keyword: keyword), 
        offset: offset,
        limit: limit);
      final newSearches = contacts.expand((contact) => contact.toSearch()).toList();
      final shouldLoadMoreContacts = contacts.length == limit;
      final contactsOffset = shouldLoadMoreContacts ? offset + limit : offset;
      yield Right(GetContactAndRecentChatSuccess(
        searchResult: newSearches,
        contactsOffset: contactsOffset,
        shouldLoadMoreContacts: shouldLoadMoreContacts,
        keyword: keyword
      ));
    } catch (e) {
      yield Left(GetContactAndRecentChatFailed(exception: e));
    }
  }
}