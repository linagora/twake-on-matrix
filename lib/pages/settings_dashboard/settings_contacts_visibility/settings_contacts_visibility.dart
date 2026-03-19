import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/go_routes/app_route_paths.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_visibility_state.dart';
import 'package:fluffychat/domain/app_state/user_info/update_user_info_visibility_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_visibility_interactor.dart';
import 'package:fluffychat/domain/usecase/user_info/update_user_info_visibility_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class SettingsContactsVisibility extends StatefulWidget {
  const SettingsContactsVisibility({super.key});

  @override
  State<SettingsContactsVisibility> createState() =>
      SettingsContactsVisibilityController();
}

class SettingsContactsVisibilityController
    extends State<SettingsContactsVisibility> {
  Client get client => Matrix.read(context).client;

  void onBack() {
    context.go(AppRoutePaths.roomsSecurityFull);
  }

  StreamSubscription? getUserInfoVisibilityStreamSub;

  StreamSubscription? updateUserInfoVisibilityStreamSub;

  final getUserInfoVisibilityNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(GettingUserInfoVisibility()),
  );

  final updateUserInfoVisibilityNotifier =
      ValueNotifier<Either<Failure, Success>>(
        Right(UpdatingUserInfoVisibility()),
      );

  final visibilityOptions = [
    SettingsContactsVisibilityEnum.public,
    SettingsContactsVisibilityEnum.contacts,
    SettingsContactsVisibilityEnum.private,
  ];

  final visibleFieldsOptions = [VisibleEnum.phone, VisibleEnum.email];

  final selectedVisibilityOptionNotifier =
      ValueNotifier<SettingsContactsVisibilityEnum?>(null);

  final selectedVisibleFieldNotifier = ValueNotifier<List<VisibleEnum>>([]);

  void onSelectVisibilityOption(SettingsContactsVisibilityEnum option) {
    if (option == selectedVisibilityOptionNotifier.value) {
      return;
    }
    switch (option) {
      case .private:
        updateUserInfoVisibility(
          userInfoVisibility: UserInfoVisibilityRequest(
            visibility: option.name,
            visibleFields: visibleFieldsOptions,
          ),
        );
        break;
      case .public:
      case .contacts:
        updateUserInfoVisibility(
          userInfoVisibility: UserInfoVisibilityRequest(
            visibility: option.name,
            visibleFields: selectedVisibleFieldNotifier.value.isEmpty
                ? visibleFieldsOptions
                : selectedVisibleFieldNotifier.value,
          ),
        );
        break;
    }
  }

  void onUpdateVisibleFields(VisibleEnum selectedField) {
    final currentVisibleFields =
        selectedVisibleFieldNotifier.value.contains(selectedField)
        ? selectedVisibleFieldNotifier.value
              .where((field) => field != selectedField)
              .toList()
        : [...selectedVisibleFieldNotifier.value, selectedField];
    updateUserInfoVisibility(
      userInfoVisibility: UserInfoVisibilityRequest(
        visibility:
            selectedVisibilityOptionNotifier.value?.name ??
            SettingsContactsVisibilityEnum.contacts.name,
        visibleFields: currentVisibleFields,
      ),
    );
  }

  void updateUserInfoVisibility({
    required UserInfoVisibilityRequest userInfoVisibility,
  }) {
    final l10n = L10n.of(context)!;
    if (client.userID == null) {
      TwakeSnackBar.show(context, l10n.failedToChangeContactsVisibility);
      return;
    }
    updateUserInfoVisibilityStreamSub?.cancel();
    updateUserInfoVisibilityStreamSub = getIt
        .get<UpdateUserInfoVisibilityInteractor>()
        .execute(userId: client.userID!, body: userInfoVisibility)
        .listen((either) {
          if (!mounted) return;
          updateUserInfoVisibilityNotifier.value = either;

          either.fold(
            (failure) {
              if (failure is UpdateUserInfoVisibilityFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  l10n.failedToChangeContactsVisibility,
                );
              }
            },
            (success) {
              if (success is UpdateUserInfoVisibilitySuccess) {
                selectedVisibilityOptionNotifier.value =
                    SettingsContactsVisibilityEnum.values.firstWhere(
                      (option) =>
                          option.name == success.userInfoVisibility.visibility,
                      orElse: () => .contacts,
                    );
                selectedVisibleFieldNotifier.value =
                    success.userInfoVisibility.visibleFields ?? [];
                TwakeDialog.hideLoadingDialog(context);
              }

              if (success is UpdatingUserInfoVisibility) {
                TwakeDialog.showLoadingDialog(context);
              }
            },
          );
        });
  }

  void initialGetUserInfoVisibility() {
    if (client.userID == null) {
      return;
    }
    getUserInfoVisibilityStreamSub?.cancel();
    getUserInfoVisibilityStreamSub = getIt
        .get<GetUserInfoVisibilityInteractor>()
        .execute(userId: client.userID!)
        .listen((either) {
          if (!mounted) return;
          getUserInfoVisibilityNotifier.value = either;

          either.fold(
            (failure) {
              if (failure is GetUserInfoVisibilityFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.failedToGetContactsVisibility,
                );
              }
            },
            (success) {
              if (success is GettingUserInfoVisibility) {
                TwakeDialog.showLoadingDialog(context);
              }

              if (success is GetUserInfoVisibilitySuccess) {
                selectedVisibilityOptionNotifier.value =
                    SettingsContactsVisibilityEnum.values.firstWhere(
                      (option) =>
                          option.name == success.userInfoVisibility.visibility,
                      orElse: () => .contacts,
                    );
                selectedVisibleFieldNotifier.value =
                    success.userInfoVisibility.visibleFields ?? [];
                TwakeDialog.hideLoadingDialog(context);
              }
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
    initialGetUserInfoVisibility();
  }

  @override
  void dispose() {
    getUserInfoVisibilityStreamSub?.cancel();
    updateUserInfoVisibilityStreamSub?.cancel();
    selectedVisibleFieldNotifier.dispose();
    selectedVisibilityOptionNotifier.dispose();
    getUserInfoVisibilityNotifier.dispose();
    updateUserInfoVisibilityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return SettingsContactsVisibilityView(controller: this);
  }
}
