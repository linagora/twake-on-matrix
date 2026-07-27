import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/bootstrap/read_cached_recovery_key_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/start_self_verification_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/store_recovery_key_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/unlock_ssss_with_recovery_key_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bootstrap_providers.g.dart';

@riverpod
UnlockSsssWithRecoveryKeyInteractor unlockSsssWithRecoveryKeyInteractor(
  Ref ref,
) => getIt.get<UnlockSsssWithRecoveryKeyInteractor>();

@riverpod
ReadCachedRecoveryKeyInteractor readCachedRecoveryKeyInteractor(Ref ref) =>
    getIt.get<ReadCachedRecoveryKeyInteractor>();

@riverpod
StoreRecoveryKeyInteractor storeRecoveryKeyInteractor(Ref ref) =>
    getIt.get<StoreRecoveryKeyInteractor>();

@riverpod
StartSelfVerificationInteractor startSelfVerificationInteractor(Ref ref) =>
    getIt.get<StartSelfVerificationInteractor>();
