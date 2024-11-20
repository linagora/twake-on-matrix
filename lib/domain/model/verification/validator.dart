import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

abstract class Validator<T> {
  Either<Failure, Success> validate(T value);
}
