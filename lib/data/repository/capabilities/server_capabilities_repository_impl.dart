import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';

class ServerCapabilitiesRepositoryImpl implements ServerCapabilitiesRepository {
  const ServerCapabilitiesRepositoryImpl(this._datasource);

  final ServerCapabilitiesDatasource _datasource;

  @override
  Future<ProfileEditCapabilities> getProfileEditCapabilities() =>
      _datasource.getProfileEditCapabilities();
}
