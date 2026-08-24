import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/matrix.dart';

part 'store_recovery_key_interactor.freezed.dart';

@Freezed(equal: false)
abstract class StoreRecoveryKeySuccessState extends Success
    with _$StoreRecoveryKeySuccessState {
  const StoreRecoveryKeySuccessState._();

  const factory StoreRecoveryKeySuccessState() = _StoreRecoveryKeySuccessState;

  @override
  List<Object?> get props => [];
}

@Freezed(equal: false)
abstract class StoreRecoveryKeyFailureState extends Failure
    with _$StoreRecoveryKeyFailureState {
  const StoreRecoveryKeyFailureState._();

  const factory StoreRecoveryKeyFailureState({required dynamic exception}) =
      _StoreRecoveryKeyFailureState;

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
