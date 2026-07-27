import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class StoreRecoveryKeySuccessState extends Success {
  const StoreRecoveryKeySuccessState() : super();

  @override
  List<Object?> get props => [];
}

class StoreRecoveryKeyFailureState extends Failure {
  final dynamic exception;

  const StoreRecoveryKeyFailureState({required this.exception});

  @override
  List<Object?> get props => [exception];
}

/// Caches [recoveryKey] in secure storage under [userId], so a later
/// bootstrap run (e.g. "Retry automatically") can prefill/auto-unlock
/// without asking the user to re-enter it.
class StoreRecoveryKeyInteractor {
  static String _secureStorageKey(String userId) => 'ssss_recovery_key_$userId';

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String recoveryKey,
  }) async* {
    try {
      await const FlutterSecureStorage().write(
        key: _secureStorageKey(userId),
        value: recoveryKey,
      );
      yield const Right(StoreRecoveryKeySuccessState());
    } catch (e, s) {
      Logs().w('Unable to store recovery key', e, s);
      yield Left(StoreRecoveryKeyFailureState(exception: e));
    }
  }
}
