import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:fluffychat/utils/image_download_queue.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin GetPreviewUrlMixin {
  static const int _defaultPreferredPreviewTimeInMilliseconds = 2000;

  final GetPreviewURLInteractor _getPreviewURLInteractor = getIt
      .get<GetPreviewURLInteractor>();

  final getPreviewUrlStateNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(GetPreviewUrlInitial()),
  );

  StreamSubscription<Either<Failure, Success>>? _previewUrlSubscription;

  /// Ticket from the shared download queue to limit concurrent HTTP requests.
  ImageDownloadTicket? _previewTicket;

  abstract String debugLabel;

  void getPreviewUrl({
    required Uri uri,
    int preferredPreviewTime = _defaultPreferredPreviewTimeInMilliseconds,
  }) {
    _previewUrlSubscription?.cancel();

    // Acquire a slot from the shared download queue to prevent
    // dozens of preview_url HTTP requests from firing simultaneously.
    final ticket = ImageDownloadQueue.instance.acquire();
    _previewTicket = ticket;

    ticket.ready.then((shouldProceed) {
      if (!shouldProceed) return;

      _previewUrlSubscription = _getPreviewURLInteractor
          .execute(uri: uri, preferredPreviewTime: preferredPreviewTime)
          .listen(
            _handleGetPreviewUrlOnData,
            onError: _handleGetPreviewUrlOnError,
            onDone: () {
              _handleGetPreviewUrlOnDone();
              _releasePreviewTicket();
            },
          );
    });
  }

  void _releasePreviewTicket() {
    final ticket = _previewTicket;
    if (ticket != null) {
      if (ticket.isActive) {
        ImageDownloadQueue.instance.release(ticket);
      }
      _previewTicket = null;
    }
  }

  void disposeGetPreviewUrlMixin() {
    _previewUrlSubscription?.cancel();
    _previewUrlSubscription = null;

    final ticket = _previewTicket;
    if (ticket != null) {
      if (ticket.isActive) {
        ImageDownloadQueue.instance.release(ticket);
      } else {
        ticket.cancel();
      }
      _previewTicket = null;
    }

    getPreviewUrlStateNotifier.dispose();
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
    _releasePreviewTicket();
  }
}
