import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_account_profiles_usecase.provider.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_own_profile_usecase.provider.dart';
import 'package:twake_chat/domain/profile/usecases/remove_own_avatar_usecase.provider.dart';
import 'package:twake_chat/domain/profile/usecases/save_own_profile_usecase.provider.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_state.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'settings_profile_controller.g.dart';

@riverpod
class SettingsProfileController extends _$SettingsProfileController {
  int _saveRevision = 0;

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

  /// Throws [SaveOwnProfileException]. Re-reads the server either way: a
  /// failed save may have written part of the profile.
  Future<void> save({String? displayName, AvatarUpload? avatar}) async {
    final profile = state.value?.profile;
    if (profile == null) return;
    try {
      final saved = await ref
          .read(saveOwnProfileUseCaseProvider)
          .execute(profile, displayName: displayName, avatar: avatar);
      if (!ref.mounted) return;
      _applySave(saved);
    } finally {
      if (ref.mounted) unawaited(_refresh());
    }
  }

  /// Throws [RemoveOwnAvatarException]. Re-reads the server either way.
  Future<void> removeAvatar() async {
    final profile = state.value?.profile;
    if (profile == null) return;
    try {
      final saved = await ref
          .read(removeOwnAvatarUseCaseProvider)
          .execute(profile);
      if (!ref.mounted) return;
      _applySave(saved);
    } finally {
      if (ref.mounted) unawaited(_refresh());
    }
  }

  void _applySave(AccountProfile saved) {
    _saveRevision++;
    _show(saved);
  }

  void _show(AccountProfile profile) {
    if (!state.hasValue) return;
    state = AsyncData(SettingsProfileState(profile: profile));
  }

  /// A failed read keeps the profile shown, and so does a read that a later
  /// save made stale.
  Future<void> _refresh() async {
    final userId = state.value?.profile.userId;
    if (userId == null) return;
    final revision = _saveRevision;
    final AccountProfile? profile;
    try {
      profile = await ref
          .read(fetchOwnProfileUseCaseProvider)
          .execute(userId, fresh: true);
    } on FetchOwnProfileException {
      return;
    }
    if (!ref.mounted || revision != _saveRevision) return;
    if (profile != null) _show(profile);
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
