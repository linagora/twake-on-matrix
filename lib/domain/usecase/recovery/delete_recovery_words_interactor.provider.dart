import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';

part 'delete_recovery_words_interactor.provider.g.dart';

// TODO: [transitional] GetIt interactor for TomBootstrapController and TomEncryptionResetService until delete gets its Patrol scenarios.
@riverpod
DeleteRecoveryWordsInteractor deleteRecoveryWordsInteractor(Ref ref) =>
    getIt.get<DeleteRecoveryWordsInteractor>();
