import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';
import 'package:twake_chat/data/account/login_configuration_persister.dart';

class _Client extends Fake implements Client {
  _Client(this.userID);

  @override
  final String? userID;

  @override
  String get clientName => 'client';
}

class _Tom extends Fake implements ToMConfigurationsRepository {
  final saved = <String>[];
  Object? failure;

  @override
  Future<void> saveTomConfigurations(
    String userId,
    ToMConfigurations configurations,
  ) async {
    if (failure != null) throw failure!;
    saved.add(userId);
  }
}

class _Federation extends Fake implements FederationConfigurationsRepository {
  final saved = <String>[];
  Object? failure;

  @override
  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations configurations,
  ) async {
    if (failure != null) throw failure!;
    saved.add(userId);
  }
}

class _Config extends Fake implements ToMConfigurations {}

class _FedConfig extends Fake implements FederationConfigurations {}

void main() {
  late _Tom tom;
  late _Federation federation;
  late LoginConfigurationPersister persister;

  setUp(() {
    tom = _Tom();
    federation = _Federation();
    persister = LoginConfigurationPersister(
      tom: () => tom,
      federation: () => federation,
    );
  });

  test('saves the ToM configuration of the user', () async {
    await persister.saveToM(_Client('@a:s'), _Config());

    expect(tom.saved, ['@a:s']);
  });

  test('saves the federation configuration of the user', () async {
    await persister.saveFederation(_Client('@a:s'), _FedConfig());

    expect(federation.saved, ['@a:s']);
  });

  test('a ToM configuration that cannot be saved is an error', () async {
    tom.failure = StateError('disk');

    await expectLater(
      persister.saveToM(_Client('@a:s'), _Config()),
      throwsStateError,
    );
  });

  test('a federation configuration that cannot be saved is an error', () async {
    federation.failure = StateError('disk');

    await expectLater(
      persister.saveFederation(_Client('@a:s'), _FedConfig()),
      throwsStateError,
    );
  });

  test('a client without a user id is an error, not a silent skip', () async {
    await expectLater(
      persister.saveToM(_Client(null), _Config()),
      throwsStateError,
    );
    await expectLater(
      persister.saveFederation(_Client(null), _FedConfig()),
      throwsStateError,
    );
    expect(tom.saved, isEmpty);
    expect(federation.saved, isEmpty);
  });
}
