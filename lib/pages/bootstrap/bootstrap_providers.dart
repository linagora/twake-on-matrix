import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/bootstrap/read_cached_recovery_key_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/start_self_verification_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/store_recovery_key_interactor.dart';
import 'package:fluffychat/domain/usecase/bootstrap/unlock_ssss_with_recovery_key_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bootstrap_providers.g.dart';

// These 4 interactors have no constructor dependencies, so they're
// constructed directly rather than bridged through GetIt.
@riverpod
UnlockSsssWithRecoveryKeyInteractor unlockSsssWithRecoveryKeyInteractor(
  Ref ref,
) => UnlockSsssWithRecoveryKeyInteractor();

@riverpod
ReadCachedRecoveryKeyInteractor readCachedRecoveryKeyInteractor(Ref ref) =>
    ReadCachedRecoveryKeyInteractor();

@riverpod
StoreRecoveryKeyInteractor storeRecoveryKeyInteractor(Ref ref) =>
    StoreRecoveryKeyInteractor();

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
