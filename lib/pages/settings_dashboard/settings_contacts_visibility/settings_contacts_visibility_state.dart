import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';

part 'settings_contacts_visibility_state.freezed.dart';

@freezed
abstract class SettingsContactsVisibilityState
    with _$SettingsContactsVisibilityState {
  const factory SettingsContactsVisibilityState({
    SettingsContactsVisibilityEnum? visibility,
    @Default(<VisibleEnum>[]) List<VisibleEnum> visibleFields,
  }) = _SettingsContactsVisibilityState;
}
