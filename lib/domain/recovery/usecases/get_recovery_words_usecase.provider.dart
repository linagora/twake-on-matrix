import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/recovery_words_repository.provider.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.dart';

part 'get_recovery_words_usecase.provider.g.dart';

@riverpod
GetRecoveryWordsUseCase getRecoveryWordsUseCase(Ref ref) =>
    GetRecoveryWordsUseCase(ref.watch(recoveryWordsRepositoryProvider));
