import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/tom_configurations_repository_impl.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';

part 'tom_configurations_repository_impl.provider.g.dart';

/// Kept alive: watched by the session-wide loginConfigurationPersisterProvider.
/// The repository holds no state of its own, so one instance is enough.
@Riverpod(keepAlive: true)
ToMConfigurationsRepository tomConfigurationsRepository(Ref ref) =>
    ToMConfigurationsRepositoryImpl();
