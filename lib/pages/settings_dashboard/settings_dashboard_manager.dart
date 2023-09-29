import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class SettingsDashboardManagerController {
  SettingsDashboardManagerController._privateConstructor();

  static SettingsDashboardManagerController get instance {
    _instance.initProfileNotifier();
    return _instance;
  }

  static final SettingsDashboardManagerController _instance =
      SettingsDashboardManagerController._privateConstructor();

  factory SettingsDashboardManagerController() {
    return _instance;
  }

  void getCurrentProfile(Client client) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      getFromRooms: false,
    );
    Logs().v(
      'SettingsDashboardManagerController::_getCurrentProfile() - currentProfile: $profile',
    );
    profileNotifier.value = profile;
  }

  late ValueNotifier<Profile> profileNotifier;
  late ValueNotifier<SettingEnum?> optionsSelectNotifier;

  bool initialized = false;

  void initProfileNotifier() {
    initialized = true;
    profileNotifier = ValueNotifier(
      Profile(userId: ''),
    );

    optionsSelectNotifier = ValueNotifier(null);
  }

  String mxid(BuildContext context) =>
      Matrix.of(context).client.userID ?? L10n.of(context)!.user;

  String displayName(BuildContext context) =>
      profileNotifier.value.displayName ??
      mxid(context).localpart ??
      mxid(context);

  bool optionSelected(SettingEnum settingEnum) =>
      settingEnum == optionsSelectNotifier.value;
}
