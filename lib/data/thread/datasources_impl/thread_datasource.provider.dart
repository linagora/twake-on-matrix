import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/thread/datasources/thread_datasource.dart';
import 'package:twake_chat/data/thread/datasources_impl/thread_datasource_impl.dart';

part 'thread_datasource.provider.g.dart';

@riverpod
ThreadDatasource threadDatasource(Ref ref, Client client) =>
    ThreadDatasourceImpl(client);
