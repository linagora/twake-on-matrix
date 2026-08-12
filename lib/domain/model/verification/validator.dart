import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';

abstract class Validator<T> {
  Either<Failure, Success> validate(T value);
}
