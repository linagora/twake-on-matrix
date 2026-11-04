import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/forward/forward_datasource.provider.dart';
import 'package:twake_chat/data/repository/forward/forward_repository_impl.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

part 'forward_repository.provider.g.dart';

@riverpod
ForwardRepository forwardRepository(Ref ref) =>
    ForwardRepositoryImpl(ref.watch(forwardDatasourceProvider));
