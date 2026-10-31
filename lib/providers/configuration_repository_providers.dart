import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';

part 'configuration_repository_providers.g.dart';

@Riverpod(keepAlive: true)
ToMConfigurationsRepository tomConfigurationsRepository(Ref ref) =>
    getIt.get<ToMConfigurationsRepository>();

@Riverpod(keepAlive: true)
FederationConfigurationsRepository federationConfigurationsRepository(
  Ref ref,
) => getIt.get<FederationConfigurationsRepository>();
