import 'package:matrix/matrix.dart';

extension CapabilitiesExtension on Capabilities {
  bool get _canEditProfileFields {
    return mProfileFields?.enabled != false;
  }

  bool get _canEditAvatarProfileField {
    if (!_canEditProfileFields) return false;

    final allowed = mProfileFields?.allowed;
    final disallowed = mProfileFields?.disallowed;
    if (allowed != null) {
      return allowed.contains('avatar_url');
    } else if (disallowed != null) {
      return !disallowed.contains('avatar_url');
    } else {
      return true;
    }
  }

  bool get _canEditDisplayNameProfileField {
    if (!_canEditProfileFields) return false;

    final allowed = mProfileFields?.allowed;
    final disallowed = mProfileFields?.disallowed;
    if (allowed != null) {
      return allowed.contains('displayname');
    } else if (disallowed != null) {
      return !disallowed.contains('displayname');
    } else {
      return true;
    }
  }

  bool get canEditAvatar {
    const key = 'm.set_avatar_url';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return _canEditAvatarProfileField &&
        mSetAvatarUrl?.enabled != false &&
        properties?['enabled'] != false;
  }

  bool get canEditDisplayName {
    const key = 'm.set_displayname';
    final properties = additionalProperties[key] as Map<String, dynamic>?;
    return _canEditDisplayNameProfileField &&
        mSetDisplayname?.enabled != false &&
        properties?['enabled'] != false;
  }
}
