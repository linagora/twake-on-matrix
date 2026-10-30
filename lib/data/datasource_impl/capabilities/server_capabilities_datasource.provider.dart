import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/data/datasource_impl/capabilities/server_capabilities_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'server_capabilities_datasource.provider.g.dart';

@riverpod
ServerCapabilitiesDatasource serverCapabilitiesDatasource(Ref ref) =>
    ServerCapabilitiesDatasourceImpl(
      ref.watch(activeMatrixClientProvider.select((s) => s.client)),
    );
