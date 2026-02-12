import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class DeleteThirdPartyContactBoxInitial extends Initial {
  const DeleteThirdPartyContactBoxInitial() : super();

  @override
  List<Object?> get props => [];
}

class DeleteThirdPartyContactBoxLoading extends Success {
  const DeleteThirdPartyContactBoxLoading();

  @override
  List<Object?> get props => [];
}

class DeleteThirdPartyContactBoxEmptyState extends Failure {
  const DeleteThirdPartyContactBoxEmptyState();

  @override
  List<Object?> get props => [];
}

class DeleteThirdPartyContactBoxResponseIsNullState extends Failure {
  const DeleteThirdPartyContactBoxResponseIsNullState();

  @override
  List<Object?> get props => [];
}

class DeleteThirdPartyContactBoxSuccessState extends Success {
  const DeleteThirdPartyContactBoxSuccessState();

  @override
  List<Object> get props => [];
}

class DeleteThirdPartyContactBoxFailureState extends Failure {
  final dynamic exception;

  const DeleteThirdPartyContactBoxFailureState({required this.exception});

  @override
  List<Object> get props => [exception];
}
