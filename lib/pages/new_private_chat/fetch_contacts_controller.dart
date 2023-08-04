
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/load_more_internal_contacts.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/mixins/load_more_contacts_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class FetchContactsController with LoadMoreContactsMixin {

  final _fetchContactsInteractor = getIt.get<FetchContactsInteractor>();
  final _loadMoreInternalContacts = getIt.get<LoadMoreInternalContacts>();
  final streamController = StreamController<Either<Failure, GetContactsSuccess>>();  

  void fetchCurrentTomContacts({
    int? limit,
    int? offset,
  }) {
    _fetchContactsInteractor
      .execute(limit: limit, offset: offset)
      .listen((event) {
        streamController.add(event);
      });
  }

  Set<PresentationContact> getContactsFromFetchStream(Either<Failure, GetContactsSuccess> event) {
    return event.fold<Set<PresentationContact>>(
      (failure) => <PresentationContact>{},
      (success) {
        final currentContacts = success.contacts.expand((contact) => contact.toPresentationContacts());
        updateLastContactIndex(oldContactsList.length);
        if (success is GetMoreNetworkContactSuccess) {
          _handleGetMoreContactsSuccess(currentContacts);
        } else if (success is NoMoreContactSuccess) {
          _handleNoMoreContactsSuccess(currentContacts);
        } else {
          oldContactsList = currentContacts.toSet();
          lastContactIndexNotifier.value = oldContactsList.length;
        }
        return oldContactsList;
      },
    ).toSet();
  }

  void _handleGetMoreContactsSuccess(Iterable<PresentationContact> currentContacts) {
    oldContactsList.addAll(currentContacts);
    haveMoreCountactsNotifier.value = currentContacts.isNotEmpty;
    lastContactIndexNotifier.value = oldContactsList.length;
    isLoadMore = true;
  }

  void _handleNoMoreContactsSuccess(Iterable<PresentationContact> currentContacts) {
    haveMoreCountactsNotifier.value = false;
    oldContactsList.addAll(currentContacts);
    lastContactIndexNotifier.value = oldContactsList.length;
    isLoadMore = false;
  }

  void loadMoreContacts({required int offset}) {
    if (isLoadMore) {
      isLoadMore = false;
      _loadMoreInternalContacts
        .execute(offset: offset)
        .listen((event) {
          streamController.add(event);
        });
    }
  }

  void dispose() {
    streamController.close();
  }
}