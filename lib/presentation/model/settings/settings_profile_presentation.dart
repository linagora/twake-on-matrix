import 'package:equatable/equatable.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';

class SettingsProfilePresentation extends Equatable {
  final SettingsProfileType settingsProfileType;

  bool get isEditable => settingsProfileType == SettingsProfileType.edit;

  const SettingsProfilePresentation({
    this.settingsProfileType = SettingsProfileType.edit,
  });

  @override
  List<Object?> get props => [
        settingsProfileType,
      ];
}
