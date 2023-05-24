
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';

class FetchContactsController {
  late final FetchContactsInteractor _fetchContactsInteractor = getIt.get<FetchContactsInteractor>();
  final StreamController<Either<Failure, GetContactsSuccess>> streamController = StreamController();

  void fetchCurrentTomContacts() {
    _fetchContactsInteractor
      .execute()
      .listen((event) {
        streamController.add(event);
      });
  }

  void dispose() {
    streamController.close();
  }
}