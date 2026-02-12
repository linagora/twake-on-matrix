import 'package:fluffychat/domain/model/common_settings_information.dart';

extension CommonSettingsInformationExtension on CommonSettingsInformation {
  String? completedApplicationUrl(String userId) {
    if (applicationUrl == null ||
        applicationUrl!.isEmpty ||
        !applicationUrl!.contains('{username}')) {
      return null;
    }

    final RegExp userIdRegex = RegExp(r'^@([a-zA-Z0-9._-]+):([a-zA-Z0-9.-]+)$');
    final Match? match = userIdRegex.firstMatch(userId);

    if (match == null) {
      return null;
    }

    final username = match.group(1)!;

    return applicationUrl!.replaceAll('{username}', username);
  }
}
