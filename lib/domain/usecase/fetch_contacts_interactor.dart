import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/domain/state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/state/contact/get_network_contact_failed.dart';
import 'package:fluffychat/domain/state/contact/get_network_contact_success.dart';
import 'package:fluffychat/state/failure.dart';

class FetchContactsInteractor {
  final ContactRepository contactRepository;

  FetchContactsInteractor({required this.contactRepository});

  Stream<Either<Failure, GetContactsSuccess>> execute() async* {
    try {
      // final contacts = await contactRepository.
      yield Right(GetNetworkContactSuccess(contacts: {}));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}