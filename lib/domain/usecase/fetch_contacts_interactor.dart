import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_failed.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class FetchContactsInteractor {
  final contactRepository = getIt.get<ContactRepository>();

  Stream<Either<Failure, Success>> execute() async* {
    try {
      final contacts = await contactRepository.searchContact(query: ContactQuery(keyword: ''));
      yield Right(GetNetworkContactSuccess(contacts: contacts.toSet()));
    } catch (e) {
      yield Left(GetNetworkContactFailed(exception: e));
    }
  }
}