import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource.provider.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository_impl.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

part 'thread_prefs_repository.provider.g.dart';

@riverpod
ThreadPrefsRepository threadPrefsRepository(Ref ref) =>
    ThreadPrefsRepositoryImpl(ref.watch(threadPrefsDatasourceProvider));
