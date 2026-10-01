import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/pages/new_group/group_privacy_state.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'group_privacy_view_model.g.dart';

@riverpod
class GroupPrivacyViewModel extends _$GroupPrivacyViewModel {
  @override
  GroupPrivacyState build() => const GroupPrivacyState();

  /// Also resets [GroupPrivacyState.isServerLimited] to the well-known
  /// default, or to false when the group goes back to private.
  void setPublic({required bool isPublic}) {
    state = GroupPrivacyState(
      isPublic: isPublic,
      isServerLimited:
          isPublic &&
          ref
              .read(loginHomeserverSummaryProvider)
              .isPublicGroupsServerLimitedByDefault,
    );
  }

  void setServerLimited({required bool isServerLimited}) {
    state = state.copyWith(isServerLimited: isServerLimited);
  }
}
