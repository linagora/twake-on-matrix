import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_failed.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class LoadMoreInternalContacts {
  final _contactRepository = getIt.get<ContactRepository>();

  static const int limitInternalContacts = 30;

  Stream<Either<Failure, GetContactsSuccess>> execute(
      {int limit = limitInternalContacts, int? offset = 0}) async* {
    try {
      final contacts = await _contactRepository.loadMoreContact(
          query: ContactQuery(keyword: ''), limit: limit, offset: offset);

      if (contacts.isEmpty || contacts.length < limit) {
        yield Right(NoMoreContactSuccess(contacts: contacts.toSet()));
        return;
      }

      yield Right(GetMoreNetworkContactSuccess(
          contacts: contacts.toSet(), limit: limit, offset: offset));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}
