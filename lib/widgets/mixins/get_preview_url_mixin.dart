import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin GetPreviewUrlMixin<T extends StatefulWidget> on State<T> {
  static const int _defaultPreferredPreviewTimeInMilliseconds = 2000;

  final GetPreviewURLInteractor _getPreviewURLInteractor = getIt
      .get<GetPreviewURLInteractor>();

  final getPreviewUrlStateNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(GetPreviewUrlInitial()),
  );
  StreamSubscription<Either<Failure, Success>>? _getPreviewUrlSubscription;

  @override
  void dispose() {
    getPreviewUrlStateNotifier.dispose();
    _getPreviewUrlSubscription?.cancel();
    super.dispose();
  }

  abstract String debugLabel;

  void getPreviewUrl({
    required Uri uri,
    int preferredPreviewTime = _defaultPreferredPreviewTimeInMilliseconds,
  }) {
    _getPreviewUrlSubscription?.cancel();
    _getPreviewUrlSubscription = _getPreviewURLInteractor
        .execute(uri: uri, preferredPreviewTime: preferredPreviewTime)
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
    Logs().d('$debugLabel::_handleGetPreviewUrlOnDone() - done');
  }

  void _handleGetPreviewUrlOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e(
      '$debugLabel::_handleGetPreviewUrlOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  void clearPreviewUrlState() {
    _getPreviewUrlSubscription?.cancel();
    getPreviewUrlStateNotifier.value = Right(GetPreviewUrlInitial());
  }
}
