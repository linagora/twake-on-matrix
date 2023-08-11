import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/usecase/get_contacts_interactor.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/mixins/load_more_contacts_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class FetchContactsController with LoadMoreContactsMixin {
  final _fetchContactsInteractor = getIt.get<GetContactsInteractor>();
  final _loadMoreInternalContacts = getIt.get<GetContactsInteractor>();
  final streamController = StreamController<Either<Failure, Success>>();

  void fetchCurrentTomContacts({
    int? limit,
    int? offset,
  }) {
    _fetchContactsInteractor
        .execute(
      keyword: '',
      offset: offset ?? 0,
      limit: limit ?? AppConfig.fetchLimit,
    )
        .listen((event) {
      streamController.add(event);
    });
  }

  Set<PresentationContact> getContactsFromFetchStream(
    Either<Failure, Success> event,
  ) {
    return event.fold<Set<PresentationContact>>(
      (failure) => <PresentationContact>{},
      (success) {
        if (success is GetContactsSuccess) {
          final currentContacts = success.data
              .expand((contact) => contact.toPresentationContacts());
          updateLastContactIndex(oldContactsList.length);
          if (!success.isEnd) {
            _handleGetMoreContactsSuccess(currentContacts);
          } else {
            _handleNoMoreContactsSuccess(currentContacts);
          }
        }
        return oldContactsList;
      },
    ).toSet();
  }

  void _handleGetMoreContactsSuccess(
    Iterable<PresentationContact> currentContacts,
  ) {
    oldContactsList.addAll(currentContacts);
    haveMoreCountactsNotifier.value = currentContacts.isNotEmpty;
    lastContactIndexNotifier.value = oldContactsList.length;
    isLoadMore = true;
  }

  void _handleNoMoreContactsSuccess(
    Iterable<PresentationContact> currentContacts,
  ) {
    haveMoreCountactsNotifier.value = false;
    oldContactsList.addAll(currentContacts);
    lastContactIndexNotifier.value = oldContactsList.length;
    isLoadMore = false;
  }

  void loadMoreContacts({required int offset, required int limit}) {
    if (isLoadMore) {
      isLoadMore = false;
      _loadMoreInternalContacts
          .execute(offset: offset, keyword: '', limit: limit)
          .listen((event) {
        streamController.add(event);
      });
    }
  }

  void dispose() {
    streamController.close();
  }
}
