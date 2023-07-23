import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/load_more_internal_contacts.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/presentation/mixin/load_more_contacts_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class FetchContactsController with LoadMoreContactsMixin, ComparablePresentationContactMixin {

  final _fetchContactsInteractor = getIt.get<FetchContactsInteractor>();
  final _loadMoreInternalContacts = getIt.get<LoadMoreInternalContacts>();
  final streamController = StreamController<Either<Failure, Success>>();

  void fetchCurrentTomContacts() {
    _fetchContactsInteractor
      .execute()
      .listen((event) {
        streamController.add(event);
      });
  }

  List<PresentationContact> getContactsFromFetchStream(Either<Failure, Success> event) {
    return event.fold<Set<PresentationContact>>(
      (failure) => <PresentationContact>{},
      (success) {
        if (success is GetNetworkContactSuccess) {
          _handleGetNetworkContactSuccess(success);
        } else if (success is GetMoreNetworkContactSuccess) {
          _handleGetMoreContactsSuccess(success);
        } else if (success is NoMoreContactSuccess) {
          _handleNoMoreContactsSuccess(success);
        } else {
          lastContactIndexNotifier.value = oldContactsList.length;
        }
        return oldContactsList;
      }
    ).toSet().sorted((cur, next) => comparePresentationContacts(cur, next));
  }

  void _handleGetNetworkContactSuccess(GetNetworkContactSuccess success) {
    updateLastContactIndex(oldContactsList.length);
    oldContactsList = success.contacts.expand((contact) => contact.toPresentationContacts()).toSet();
  }

  void _handleGetMoreContactsSuccess(GetMoreNetworkContactSuccess success) {
    final presentationContacts = success.contacts.expand((contact) => contact.toPresentationContacts());
    oldContactsList.addAll(presentationContacts);
    haveMoreCountactsNotifier.value = success.contacts.isNotEmpty;
    lastContactIndexNotifier.value = oldContactsList.length;
    isLoadMore = true;
  }

  void _handleNoMoreContactsSuccess(NoMoreContactSuccess success) {
    final presentationContacts = success.contacts.expand((contact) => contact.toPresentationContacts());
    haveMoreCountactsNotifier.value = false;
    oldContactsList.addAll(presentationContacts);
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