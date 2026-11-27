import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';

part 'settings_profile_state.freezed.dart';

@freezed
abstract class SettingsProfileState with _$SettingsProfileState {
  const factory SettingsProfileState({required AccountProfile profile}) =
      _SettingsProfileState;
}
