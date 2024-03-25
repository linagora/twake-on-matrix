import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class DownloadFileInfo with EquatableMixin {
  final String eventId;

  final CancelToken cancelToken;

  final StreamController<Either<Failure, Success>>
      downloadStateStreamController;

  final Stream<Either<Failure, Success>> downloadStream;

  DownloadFileInfo({
    required this.eventId,
    required this.cancelToken,
    required this.downloadStateStreamController,
    required this.downloadStream,
  });

  @override
  List<Object?> get props =>
      [eventId, cancelToken, downloadStateStreamController, downloadStream];
}
