import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_account_profiles_usecase.provider.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_own_profile_usecase.provider.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_state.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'settings_profile_controller.g.dart';

@riverpod
class SettingsProfileController extends _$SettingsProfileController {
  @override
  Future<SettingsProfileState> build() async {
    final userId = ref.watch(activeUserIdProvider);
    if (userId == null) throw const NoActiveClientException();
    final fetchOwnProfile = ref.watch(fetchOwnProfileUseCaseProvider);
    AccountProfile? profile;
    try {
      profile = await fetchOwnProfile.execute(userId);
    } on FetchOwnProfileException {
      profile = null;
    }
    return SettingsProfileState(
      profile: profile ?? AccountProfile(userId: userId),
    );
  }

  // TODO: [transitional] #3827 The screen pushes the saved profile until the save moves here.
  void applySaved(AccountProfile profile) {
    if (!state.hasValue) return;
    state = AsyncData(SettingsProfileState(profile: profile));
  }

  /// Reads the profile from the server again; a failed read keeps the
  /// profile shown.
  Future<void> refresh() async {
    final userId = state.value?.profile.userId;
    if (userId == null) return;
    final AccountProfile? profile;
    try {
      profile = await ref
          .read(fetchOwnProfileUseCaseProvider)
          .execute(userId, fresh: true);
    } on FetchOwnProfileException {
      return;
    }
    if (!ref.mounted) return;
    if (profile != null) applySaved(profile);
  }
}

/// Null when the accounts could not be read.
@riverpod
Future<List<AccountProfile>?> settingsProfileAccounts(Ref ref) async {
  final fetchAccountProfiles = ref.watch(fetchAccountProfilesUseCaseProvider);
  try {
    return await fetchAccountProfiles.execute();
  } on FetchAccountProfilesException {
    return null;
  }
}
