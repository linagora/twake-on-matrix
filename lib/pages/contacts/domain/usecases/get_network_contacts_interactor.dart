import 'package:dartz/dartz.dart';
import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/repository/network_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_failed.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_success.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/state/failure.dart';

class GetNetworkContactsInteractor {
  final NetworkContactRepository networkContactRepository;

  GetNetworkContactsInteractor({required this.networkContactRepository});

  Stream<Either<Failure, GetNetworkContactSuccess>> execute({
    Set<Contact>? cacheContacts,
    searchKey = ''}) async* {
    try {
      if (cacheContacts != null) {
        yield Right(GetNetworkContactSuccess(contacts: cacheContacts
          .filter(searchKey: searchKey)));
        return ;
      }

      final contacts = await networkContactRepository.getContacts();
      yield Right(GetNetworkContactSuccess(contacts: contacts
        .filter(searchKey: searchKey)));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}