import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';

abstract class ServerCapabilitiesRepository {
  Future<ProfileEditCapabilities> getProfileEditCapabilities();
}
