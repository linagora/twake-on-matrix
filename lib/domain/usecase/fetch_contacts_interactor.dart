import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';

class FetchContactsInteractor {
  Stream<Either<Failure, GetContactsSuccess>> execute() async* {
    yield Right(GetNetworkContactSuccess(contacts: {}));
  }
}