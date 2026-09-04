import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twake_chat/data/repository/recovery_key_storage_repository_impl.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/recovery_key_storage_repository.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/read_cached_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';
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

// These 3 predate this feature and are still consumed by non-Riverpod
// call sites (e.g. background_push.dart), so they stay registered in
// GetIt; these providers just give Riverpod consumers a `ref.read` path
// instead of reaching into GetIt directly.
@riverpod
SaveRecoveryWordsInteractor saveRecoveryWordsInteractor(Ref ref) =>
    getIt.get<SaveRecoveryWordsInteractor>();

@riverpod
GetRecoveryWordsInteractor getRecoveryWordsInteractor(Ref ref) =>
    getIt.get<GetRecoveryWordsInteractor>();

@riverpod
DeleteRecoveryWordsInteractor deleteRecoveryWordsInteractor(Ref ref) =>
    getIt.get<DeleteRecoveryWordsInteractor>();
