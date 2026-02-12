import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_visibility_state.dart';
import 'package:fluffychat/domain/app_state/user_info/update_user_info_visibility_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_visibility_interactor.dart';
import 'package:fluffychat/domain/usecase/user_info/update_user_info_visibility_interactor.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
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
    context.go('/rooms/security');
  }

  StreamSubscription? getUserInfoVisibilityStreamSub;

  StreamSubscription? updateUserInfoVisibilityStreamSub;

  final getUserInfoVisibilityInteractor = getIt
      .get<GetUserInfoVisibilityInteractor>();

  final updateUserInfoVisibilityInteractor = getIt
      .get<UpdateUserInfoVisibilityInteractor>();

  final ValueNotifier<Either<Failure, Success>> getUserInfoVisibilityNotifier =
      ValueNotifier<Either<Failure, Success>>(
        Right(GettingUserInfoVisibility()),
      );

  final ValueNotifier<Either<Failure, Success>>
  updateUserInfoVisibilityNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(UpdatingUserInfoVisibility()),
  );

  final List<SettingsContactsVisibilityEnum> visibilityOptions = [
    SettingsContactsVisibilityEnum.public,
    SettingsContactsVisibilityEnum.contacts,
    SettingsContactsVisibilityEnum.private,
  ];

  final List<VisibleEnum> visibleFieldsOptions = [
    VisibleEnum.phone,
    VisibleEnum.email,
  ];

  final ValueNotifier<SettingsContactsVisibilityEnum?>
  selectedVisibilityOptionNotifier =
      ValueNotifier<SettingsContactsVisibilityEnum?>(null);

  final ValueNotifier<List<VisibleEnum>> selectedVisibleFieldNotifier =
      ValueNotifier<List<VisibleEnum>>([]);

  void onSelectVisibilityOption(SettingsContactsVisibilityEnum option) {
    if (option == selectedVisibilityOptionNotifier.value) {
      return;
    }
    switch (option) {
      case SettingsContactsVisibilityEnum.private:
        updateUserInfoVisibility(
          userInfoVisibility: UserInfoVisibilityRequest(
            visibility: option.name,
            visibleFields: visibleFieldsOptions,
          ),
        );
        break;
      case SettingsContactsVisibilityEnum.public:
      case SettingsContactsVisibilityEnum.contacts:
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
    if (client.userID == null) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.failedToChangeContactsVisibility,
      );
      return;
    }
    updateUserInfoVisibilityStreamSub?.cancel();
    updateUserInfoVisibilityStreamSub = updateUserInfoVisibilityInteractor
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
                  L10n.of(context)!.failedToChangeContactsVisibility,
                );
              }
            },
            (success) {
              if (success is UpdateUserInfoVisibilitySuccess) {
                selectedVisibilityOptionNotifier.value =
                    SettingsContactsVisibilityEnum.values.firstWhere(
                      (option) =>
                          option.name == success.userInfoVisibility.visibility,
                      orElse: () => SettingsContactsVisibilityEnum.contacts,
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
    getUserInfoVisibilityStreamSub = getUserInfoVisibilityInteractor
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
                      orElse: () => SettingsContactsVisibilityEnum.contacts,
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
  Widget build(BuildContext context) {
    return SettingsContactsVisibilityView(controller: this);
  }
}
