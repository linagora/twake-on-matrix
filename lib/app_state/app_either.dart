import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter/foundation.dart';

typedef AppEither = Either<Failure, Success>;
typedef AppEitherNotifier = ValueNotifier<AppEither>;

abstract class SuccessConverter {
  Success convert(Success success);
}
