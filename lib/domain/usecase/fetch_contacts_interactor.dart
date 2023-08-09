import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_failed.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class FetchContactsInteractor {
  final contactRepository = getIt.get<ContactRepository>();

  Stream<Either<Failure, GetNetworkContactSuccess>> execute({
    int? limit,
    int? offset,
  }) async* {
    try {
      final query = ContactQuery(keyword: '');
      final contacts = await contactRepository.searchContact(
        query: query,
        limit: limit,
        offset: offset,
      );
      yield Right(GetNetworkContactSuccess(contacts: contacts.toSet()));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}
