import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin GetPreviewUrlMixin {
  static const int _defaultPreferredPreviewTimeInMilliseconds = 2000;

  final GetPreviewURLInteractor _getPreviewURLInteractor =
      getIt.get<GetPreviewURLInteractor>();

  final getPreviewUrlStateNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(GetPreviewUrlInitial()));

  abstract String debugLabel;

  void getPreviewUrl({
    required Uri uri,
    int preferredPreviewTime = _defaultPreferredPreviewTimeInMilliseconds,
  }) {
    _getPreviewURLInteractor
        .execute(
          uri: uri,
          preferredPreviewTime: preferredPreviewTime,
        )
        .listen(
          _handleGetPreviewUrlOnData,
          onError: _handleGetPreviewUrlOnError,
          onDone: _handleGetPreviewUrlOnDone,
        );
  }

  void _handleGetPreviewUrlOnData(Either<Failure, Success> event) {
    Logs().d('$debugLabel::_handleGetPreviewUrlOnData()');
    getPreviewUrlStateNotifier.value = event;
  }

  void _handleGetPreviewUrlOnDone() {
    Logs().d(
      '$debugLabel::_handleGetPreviewUrlOnDone() - done',
    );
  }

  void _handleGetPreviewUrlOnError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    Logs().e(
      '$debugLabel::_handleGetPreviewUrlOnError() - error: $error | stackTrace: $stackTrace',
    );
  }
}
