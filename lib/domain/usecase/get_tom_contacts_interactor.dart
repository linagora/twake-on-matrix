import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class GetTomContactsInteractor {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  GetTomContactsInteractor();

  Stream<Either<Failure, Success>> execute({
    required int limit,
  }) async* {
    try {
      yield const Right(ContactsLoading());
      yield* contactRepository
          .fetchContacts(
        query: ContactQuery(keyword: ''),
        limit: limit,
      )
          .map((contacts) {
        return Right(
          GetContactsSuccess(contacts: contacts),
        );
      });
    } catch (e) {
      yield Left(GetContactsFailure(keyword: '', exception: e));
    }
  }
}
