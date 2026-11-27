import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/presence/datasources_impl/presence_datasource_impl.provider.dart';
import 'package:twake_chat/data/presence/repositories/presence_repository_impl.dart';
import 'package:twake_chat/domain/presence/repositories/presence_repository.dart';

part 'presence_repository_impl.provider.g.dart';

@riverpod
PresenceRepository presenceRepository(Ref ref) =>
    PresenceRepositoryImpl(ref.watch(presenceDatasourceProvider));
