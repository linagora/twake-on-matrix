import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/thread/datasources_impl/thread_datasource.provider.dart';
import 'package:twake_chat/data/thread/repositories/thread_repository_impl.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';

part 'thread_repository.provider.g.dart';

@riverpod
ThreadRepository<Event> threadRepository(Ref ref, Client client) =>
    ThreadRepositoryImpl(ref.watch(threadDatasourceProvider(client)));
