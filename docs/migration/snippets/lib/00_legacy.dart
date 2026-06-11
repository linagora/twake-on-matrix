// BEFORE MIGRATION
// lib/presentation/mixins/invitation_status_mixin.dart
//
// This file illustrates the current pattern of the codebase.
// The referenced types (GetIt, TwakeSnackBar, etc.) belong to the main
// project (package:fluffychat) and are not available in this package.

/*

import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:fluffychat/domain/interactors/invitation/generate_invitation_link_interactor.dart';
import 'package:fluffychat/widgets/twake_components/twake_dialog/twake_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_snackbar/twake_snack_bar.dart';

final generateLinkInteractor = getIt.get<GenerateInvitationLinkInteractor>();

StreamSubscription? _generateLinkSub;

void onGenerateLink() {
  _generateLinkSub = generateLinkInteractor
      .execute()
      .listen(
        (event) => event.fold(
          (failure) {
            if (failure is GenerateInvitationLinkFailure) {
              TwakeSnackBar.show(context, failure.exception.toString());
            }
          },
          (success) {
            if (success is GenerateInvitationLinkLoading) {
              TwakeDialog.showLoadingDialog(context);
            }
            if (success is GenerateInvitationLinkSuccess) {
              TwakeDialog.hideLoadingDialog(context);
              setState(() => _link = success.link);
            }
          },
        ),
      );
}

void dispose() {
  _generateLinkSub?.cancel();
}

*/
