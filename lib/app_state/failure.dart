import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();
}

abstract class FeatureFailure extends Failure {
  final dynamic exception;

  const FeatureFailure({this.exception});

  @override
  List<Object?> get props => [exception];
}
