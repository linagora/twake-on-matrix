import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rxdart/rxdart.dart';

class StreamControllerConverter
    implements
        JsonConverter<StreamController<Either<Failure, Success>>, dynamic> {
  const StreamControllerConverter();

  @override
  StreamController<Either<Failure, Success>> fromJson(dynamic _) =>
      BehaviorSubject<Either<Failure, Success>>();

  @override
  dynamic toJson(StreamController<Either<Failure, Success>> _) => null;
}
