import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository.provider.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_pref_use_case.dart';

part 'save_thread_pref_use_case.provider.g.dart';

@riverpod
SaveThreadPrefUseCase saveThreadPrefUseCase(Ref ref) =>
    SaveThreadPrefUseCase(ref.watch(threadPrefsRepositoryProvider));
