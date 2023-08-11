import 'package:dartz/dartz.dart';

import 'package:fluffychat/app_state/app_either.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/usecase/get_contacts_interactor.dart';

class GetContactsController {
  SuccessConverter converter;
  GetContactsController(this.converter);

  final _getContactsInteractor = getIt.get<GetContactsInteractor>();
  final contactsNotifier = AppEitherNotifier(
    const Right(GetContactsInitial()),
  );
  bool _isLoadMore = false;
  AppEither? _oldResult;

  void fetch({
    required String keyword,
    int limit = AppConfig.fetchLimit,
  }) {
    _getContactsInteractor
        .execute(keyword: keyword, offset: 0, limit: limit)
        .listen((event) {
      _oldResult = event;
      contactsNotifier.value = event.map((r) => converter.convert(r));
    });
  }

  void loadMore({
    int limit = AppConfig.fetchLimit,
  }) =>
      _oldResult?.fold(
        (failure) {},
        (success) {
          if (_isLoadMore || success is! GetContactsSuccess || success.isEnd) {
            return;
          }
          _isLoadMore = true;
          _getContactsInteractor
              .execute(
            keyword: success.keyword,
            offset: success.offset,
            limit: limit,
          )
              .listen(
            (event) {
              _isLoadMore = false;
              contactsNotifier.value = event.map(
                (newSuccess) {
                  final expandedSuccess = newSuccess is GetContactsSuccess
                      ? success + newSuccess
                      : success;
                  return converter.convert(expandedSuccess);
                },
              );
            },
          );
        },
      );

  void dispose() {
    contactsNotifier.dispose();
  }
}
