import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/domain/usecase/lazy_load_interactor.dart';

class GetContactsInteractor with LazyLoadDataMixin {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  GetContactsInteractor();

  Stream<Either<Failure, Success>> execute({
    required String keyword,
    required int offset,
    required int limit,
  }) async* {
    try {
      yield const Right(GetContactsLoading());
      final contacts = await contactRepository.searchContact(
        query: ContactQuery(keyword: keyword),
        offset: offset,
        limit: limit,
      );
      final info = calculateLazyLoadInfo(
        length: contacts.length,
        offset: offset,
        limit: limit,
      );
      yield Right(
        GetContactsSuccess(
          data: contacts,
          offset: info.offset,
          isEnd: info.isEnd,
          keyword: keyword,
        ),
      );
    } catch (e) {
      yield Left(GetContactsFailed(exception: e));
    }
  }
}
