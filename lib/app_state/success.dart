import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

abstract class Success extends Equatable {
  const Success();
}

extension SuccessExtension on Either {
  T? getSuccessOrNull<T extends Success>({T? fallbackValue}) => fold(
        (failure) => fallbackValue,
        (success) => success is T ? success : fallbackValue,
      );
}
