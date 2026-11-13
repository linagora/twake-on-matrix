import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository.provider.dart';
import 'package:twake_chat/domain/thread/usecases/watch_thread_use_case.dart';

part 'watch_thread_use_case.provider.g.dart';

@riverpod
WatchThreadUseCase watchThreadUseCase(Ref ref) =>
    WatchThreadUseCase(ref.watch(threadPrefsRepositoryProvider));
