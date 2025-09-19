import 'package:matrix/matrix.dart';

extension CapabilitiesExtension on Capabilities {
  bool get canEditAvatar {
    return additionalProperties['m.set_avatar_url']?['enabled'] == true;
  }

  bool get canEditDisplayName {
    return additionalProperties['m.set_displayname']?['enabled'] == true;
  }
}
