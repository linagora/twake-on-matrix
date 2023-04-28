
import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/domain/state/contact/get_network_contact_failed.dart';
import 'package:fluffychat/domain/state/contact/get_network_contact_success.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/state/failure.dart';

class LookupContactsInteractor {
  final ContactRepository contactRepository;

  LookupContactsInteractor({required this.contactRepository});

  Stream<Either<Failure, GetNetworkContactSuccess>> execute({
    required ContactQuery query,
    Set<Contact>? cacheContacts,
  }) async* {
    if (cacheContacts != null) {
      yield Right(GetNetworkContactSuccess(contacts: cacheContacts
        .filter(searchKey: query.keyword)));
    }

    try {
      final contacts = await contactRepository.searchContact(query: query);
      yield Right(GetNetworkContactSuccess(contacts: contacts));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}