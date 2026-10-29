import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_visibility_usecase.provider.dart';
import 'package:twake_chat/domain/user_info/usecases/update_user_info_visibility_usecase.provider.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'settings_contacts_visibility_controller.g.dart';

const _allVisibleFields = [VisibleEnum.phone, VisibleEnum.email];

@riverpod
class SettingsContactsVisibilityController
    extends _$SettingsContactsVisibilityController {
  @override
  Future<SettingsContactsVisibilityState> build() async {
    final userId = ref.watch(
      activeMatrixClientProvider.select((snapshot) => snapshot.userId),
    );
    final useCase = ref.watch(getUserInfoVisibilityUseCaseProvider);
    if (userId == null) return const SettingsContactsVisibilityState();
    return _toState(await useCase.execute(userId));
  }

  Future<void> selectVisibility(SettingsContactsVisibilityEnum option) {
    final visibleFields = _current.visibleFields;
    return _update(
      UserInfoVisibilityRequest(
        visibility: option.name,
        visibleFields:
            option == SettingsContactsVisibilityEnum.private ||
                visibleFields.isEmpty
            ? _allVisibleFields
            : visibleFields,
      ),
    );
  }

  Future<void> toggleVisibleField(VisibleEnum field) {
    final current = _current;
    return _update(
      UserInfoVisibilityRequest(
        visibility:
            (current.visibility ?? SettingsContactsVisibilityEnum.contacts)
                .name,
        visibleFields: current.visibleFields.contains(field)
            ? current.visibleFields.where((f) => f != field).toList()
            : [...current.visibleFields, field],
      ),
    );
  }

  SettingsContactsVisibilityState get _current =>
      state.value ?? const SettingsContactsVisibilityState();

  Future<void> _update(UserInfoVisibilityRequest request) async {
    final userId = ref.read(activeMatrixClientProvider).userId;
    if (userId == null) {
      throw UpdateUserInfoVisibilityException(StateError('No active account'));
    }
    final visibility = await ref
        .read(updateUserInfoVisibilityUseCaseProvider)
        .execute(userId: userId, request: request);
    if (!ref.mounted) return;
    state = AsyncData(_toState(visibility));
  }

  SettingsContactsVisibilityState _toState(UserInfoVisibility visibility) =>
      SettingsContactsVisibilityState(
        visibility: SettingsContactsVisibilityEnum.values.firstWhere(
          (option) => option.name == visibility.visibility,
          orElse: () => SettingsContactsVisibilityEnum.contacts,
        ),
        visibleFields: visibility.visibleFields ?? const [],
      );
}
