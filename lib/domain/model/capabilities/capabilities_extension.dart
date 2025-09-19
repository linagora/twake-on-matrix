import 'package:matrix/matrix.dart';

extension CapabilitiesExtension on Capabilities {
  bool get canEditAvatar {
    const key = 'm.set_avatar_url';
    return additionalProperties[key]?['enabled'] == true ||
        additionalProperties[key]?['enabled'] == null;
  }

  bool get canEditDisplayName {
    const key = 'm.set_displayname';
    return additionalProperties[key]?['enabled'] == true ||
        additionalProperties[key]?['enabled'] == null;
  }
}
