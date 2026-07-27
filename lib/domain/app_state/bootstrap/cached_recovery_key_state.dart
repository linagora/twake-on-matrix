import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class CachedRecoveryKeyFoundState extends Success {
  final String recoveryKey;

  const CachedRecoveryKeyFoundState({required this.recoveryKey});

  @override
  List<Object?> get props => [recoveryKey];
}

class CachedRecoveryKeyNotFoundState extends Success {
  const CachedRecoveryKeyNotFoundState() : super();

  @override
  List<Object?> get props => [];
}

class ReadCachedRecoveryKeyFailureState extends Failure {
  final dynamic exception;

  const ReadCachedRecoveryKeyFailureState({required this.exception});

  @override
  List<Object?> get props => [exception];
}
