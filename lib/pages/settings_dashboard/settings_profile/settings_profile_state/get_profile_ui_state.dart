import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/settings_profile_ui_state.dart';
import 'package:matrix/matrix.dart';

class GetProfileUIStateSuccess extends SettingsProfileUIState {
  final Profile profile;

  GetProfileUIStateSuccess(this.profile);

  @override
  List<Object> get props => [profile];
}
