import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
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
      yield Right(GetContactsSuccess(contacts: {
        Contact(emails: {"qkdo@linagora.com"}, displayName: "Quang Nguyen", matrixId: "@sherlock:matrix.org"),
        Contact(emails: {"qkdo1@linagora.com"}, displayName: "QK Nguyen", matrixId: "@sherlock2:matrix.org"),
        Contact(emails: {"qkdo2@linagora.com"}, displayName: "Quang eqpweo", matrixId: "@sherlock3:matrix.org"),
        Contact(emails: {"qkdo3@linagora.com"}, displayName: "Qbor dqpwdo", matrixId: "@sherlock4:matrix.org"),
        Contact(emails: {"qkdo4@linagora.com"}, displayName: "Mr quang", matrixId: "@sherlock5:matrix.org")
      }));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}