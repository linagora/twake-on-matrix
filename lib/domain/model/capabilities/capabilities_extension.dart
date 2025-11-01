import 'package:matrix/matrix.dart';

extension CapabilitiesExtension on Capabilities {
  bool get canEditAvatar {
    const key = 'm.set_avatar_url';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return properties?['enabled'] == true || properties?['enabled'] == null;
  }

  bool get canEditDisplayName {
    const key = 'm.set_displayname';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return properties?['enabled'] == true || properties?['enabled'] == null;
  }
}
