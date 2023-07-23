import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin BaseController {

  final viewState = ValueNotifier<Either<Failure, Success>>(Right(UIState.idle));

  final streamController = StreamController<Either<Failure, Success>>();

  StreamSubscription? streamSubscriptionController;

  void consumeState(Stream<Either<Failure, Success>> newStateStream) async {
    Logs().d('BaseController::consumeState(): newStateStream: $newStateStream');
    streamSubscriptionController = newStateStream.listen(onData, onError: onError, onDone: onDone);
  }

  void clearState() {
    viewState.value = Right(UIState.idle);
  }

  void onData(Either<Failure, Success> newState) {
    viewState.value = newState;
    Logs().d('BaseController::consumeState(): newState: $newState');
    newState.fold(
      (failure) {
        if (failure is FeatureFailure) {
          final exception = _performFilterExceptionInError(failure.exception);
          if (exception != null) {
            handleExceptionAction(failure: failure, exception: exception);
          } else {
            handleFailureViewState(failure);
          }
        } else {
          handleFailureViewState(failure);
        }
      },
      handleSuccessViewState);
  }

  void onError(Object error, StackTrace stackTrace) {
    Logs().d('BaseController::onError():error: $error | stackTrace: $stackTrace');
    final exception = _performFilterExceptionInError(error);
    if (exception != null) {
      handleExceptionAction(exception: exception);
    } else {
      handleErrorViewState(error, stackTrace);
    }
  }

  void onDone() {
    Logs().d('BaseController::onDone()');
  }

  void handleFailureViewState(Failure failure) {
    Logs().d('BaseController::handleFailureViewState(): $failure');
  }

  void handleSuccessViewState(Success success) {
    Logs().d('BaseController::handleSuccessViewState(): $success');
  }

  void handleExceptionAction({Failure? failure, Exception? exception}) {
    Logs().d('BaseController::handleExceptionAction():failure: $failure | exception: $exception');
  }

  void handleErrorViewState(Object error, StackTrace stackTrace) {}

  Exception? _performFilterExceptionInError(dynamic error) {
    Logs().d('BaseController::_performFilterExceptionInError(): $error');
    return null;
  }
}