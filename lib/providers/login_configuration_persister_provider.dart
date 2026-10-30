import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/federation_configurations_repository_impl.provider.dart';
import 'package:twake_chat/data/repository/tom_configurations_repository_impl.provider.dart';
import 'package:twake_chat/data/account/login_configuration_persister.dart';

part 'login_configuration_persister_provider.g.dart';

/// Saves what a login needs to be complete; its failures are errors.
@Riverpod(keepAlive: true)
LoginConfigurationPersister loginConfigurationPersister(Ref ref) =>
    LoginConfigurationPersister(
      tom: ref.watch(tomConfigurationsRepositoryProvider),
      federation: ref.watch(federationConfigurationsRepositoryProvider),
    );
