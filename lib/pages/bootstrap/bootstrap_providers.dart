import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twake_chat/data/repository/recovery_key_storage_repository_impl.dart';
import 'package:twake_chat/domain/repository/recovery_key_storage_repository.dart';
import 'package:twake_chat/domain/usecase/recovery/read_cached_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/start_self_verification_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/store_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/unlock_ssss_with_recovery_key_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bootstrap_providers.g.dart';

@riverpod
RecoveryKeyStorageRepository recoveryKeyStorageRepository(Ref ref) =>
    const RecoveryKeyStorageRepositoryImpl(FlutterSecureStorage());

@riverpod
UnlockSsssWithRecoveryKeyInteractor unlockSsssWithRecoveryKeyInteractor(
  Ref ref,
) => UnlockSsssWithRecoveryKeyInteractor();

@riverpod
ReadCachedRecoveryKeyInteractor readCachedRecoveryKeyInteractor(Ref ref) =>
    ReadCachedRecoveryKeyInteractor(
      ref.watch(recoveryKeyStorageRepositoryProvider),
    );

@riverpod
StoreRecoveryKeyInteractor storeRecoveryKeyInteractor(Ref ref) =>
    StoreRecoveryKeyInteractor(ref.watch(recoveryKeyStorageRepositoryProvider));

@riverpod
StartSelfVerificationInteractor startSelfVerificationInteractor(Ref ref) =>
    StartSelfVerificationInteractor();
