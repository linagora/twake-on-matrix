import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository.provider.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_resolved_use_case.dart';

part 'save_thread_resolved_use_case.provider.g.dart';

@riverpod
SaveThreadResolvedUseCase saveThreadResolvedUseCase(Ref ref) =>
    SaveThreadResolvedUseCase(ref.watch(threadPrefsRepositoryProvider));
