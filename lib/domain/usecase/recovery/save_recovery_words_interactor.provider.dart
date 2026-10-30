import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';

part 'save_recovery_words_interactor.provider.g.dart';

// TODO: [transitional] GetIt interactor for TomBootstrapController and TomEncryptionResetService until save gets its Patrol scenarios.
@riverpod
SaveRecoveryWordsInteractor saveRecoveryWordsInteractor(Ref ref) =>
    getIt.get<SaveRecoveryWordsInteractor>();
