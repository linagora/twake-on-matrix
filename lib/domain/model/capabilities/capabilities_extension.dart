import 'package:matrix/matrix.dart';

extension CapabilitiesExtension on Capabilities {
  bool get _canEditProfileFields {
    return mProfileFields?.enabled != false;
  }

  bool get canEditAvatar {
    const key = 'm.set_avatar_url';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return _canEditProfileFields && properties?['enabled'] != false;
  }

  bool get canEditDisplayName {
    const key = 'm.set_displayname';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return _canEditProfileFields && properties?['enabled'] != false;
  }
}
