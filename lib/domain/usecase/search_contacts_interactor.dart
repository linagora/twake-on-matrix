import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contacts_extension.dart';
import 'package:fluffychat/domain/usecase/lazy_load_interactor.dart';

class SearchContactsInteractor with LazyLoadDataMixin {
  SearchContactsInteractor();

  Stream<Either<Failure, Success>> execute({
    required String keyword,
    required List<Contact> tomContacts,
    List<Contact>? phonebookContacts,
  }) async* {
    try {
      final contactMatched = tomContacts.searchContacts(keyword);
      yield Right(
        GetContactsSuccess(
          tomContacts: contactMatched,
          keyword: keyword,
        ),
      );
    } catch (e) {
      yield Left(GetContactsFailure(keyword: keyword, exception: e));
    }
  }
}
