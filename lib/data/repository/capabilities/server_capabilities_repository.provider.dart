import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/capabilities/server_capabilities_datasource.provider.dart';
import 'package:twake_chat/data/repository/capabilities/server_capabilities_repository_impl.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';

part 'server_capabilities_repository.provider.g.dart';

@riverpod
ServerCapabilitiesRepository serverCapabilitiesRepository(Ref ref) =>
    ServerCapabilitiesRepositoryImpl(
      ref.watch(serverCapabilitiesDatasourceProvider),
    );
