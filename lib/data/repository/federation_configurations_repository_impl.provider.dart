import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/federation_configurations_repository_impl.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';

part 'federation_configurations_repository_impl.provider.g.dart';

/// Kept alive: watched by the session-wide loginConfigurationPersisterProvider.
/// The repository holds no state of its own, so one instance is enough.
@Riverpod(keepAlive: true)
FederationConfigurationsRepository federationConfigurationsRepository(
  Ref ref,
) => FederationConfigurationsRepositoryImpl();
