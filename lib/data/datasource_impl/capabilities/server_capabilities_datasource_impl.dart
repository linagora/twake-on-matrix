import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';

class ServerCapabilitiesDatasourceImpl implements ServerCapabilitiesDatasource {
  const ServerCapabilitiesDatasourceImpl(this._client);

  final Client? _client;

  @override
  Future<ProfileEditCapabilities> fetchProfileEditCapabilities() async {
    final Capabilities capabilities;
    try {
      final client = _client;
      if (client == null) throw StateError('No active Matrix client');
      capabilities = await client.getCapabilities();
    } catch (e, s) {
      Logs().e('ServerCapabilitiesDatasourceImpl::fetch failed', e, s);
      rethrow;
    }
    return ProfileEditCapabilities(
      canEditAvatar:
          capabilities.mSetAvatarUrl?.enabled != false &&
          _canEditProfileField(capabilities, 'avatar_url'),
      canEditDisplayName:
          capabilities.mSetDisplayname?.enabled != false &&
          _canEditProfileField(capabilities, 'displayname'),
    );
  }

  bool _canEditProfileField(Capabilities capabilities, String field) {
    final profileFields = capabilities.mProfileFields;
    if (profileFields == null) return true;
    if (!profileFields.enabled) return false;
    final allowed = profileFields.allowed;
    if (allowed != null) return allowed.contains(field);
    return !(profileFields.disallowed?.contains(field) ?? false);
  }
}
