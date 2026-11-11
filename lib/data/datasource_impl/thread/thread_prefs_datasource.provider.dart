import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/thread/thread_prefs_datasource.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'thread_prefs_datasource.provider.g.dart';

@riverpod
ThreadPrefsDatasource threadPrefsDatasource(Ref ref) =>
    ThreadPrefsDatasourceImpl(ref.watch(activeMatrixClientProvider));
