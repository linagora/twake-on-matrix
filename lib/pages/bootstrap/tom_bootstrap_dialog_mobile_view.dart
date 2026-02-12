import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_mobile_style.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_skeletonizer_widget.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:lottie/lottie.dart';

class TomBootstrapDialogMobileView extends StatelessWidget {
  final String description;
  const TomBootstrapDialogMobileView({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: TomBootstrapDialogMobileStyle.paddingAppbar,
            child: Skeletonizer(
              ignoreContainers: true,
              child: Card(
                child: Row(
                  children: [
                    Text(
                      TomBootstrapDialogMobileStyle.backButtonTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          TomBootstrapDialogMobileStyle.titleScreen,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    Text(
                      TomBootstrapDialogMobileStyle.trailing,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: TomBootstrapDialogMobileStyle.paddingTextField,
            child: TextField(
              textInputAction: TextInputAction.search,
              enabled: false,
              contextMenuBuilder: mobileTwakeContextMenuBuilder,
              decoration: ChatListHeaderStyle.searchInputDecoration(
                context,
                hintText: '',
                prefixIconColor: LinagoraRefColors.material().neutral[90],
              ),
            ),
          ),
          Padding(
            padding: TomBootstrapDialogMobileStyle.paddingDivider,
            child: Divider(
              height: 1,
              color: LinagoraStateLayer(
                LinagoraSysColors.material().surfaceTintDark,
              ).opacityLayer3,
            ),
          ),
          SizedBox(
            height: TomBootstrapDialogStyle.sizedDialogWeb,
            width: TomBootstrapDialogStyle.sizedDialogWeb,
            child: Padding(
              padding: TomBootstrapDialogStyle.paddingDialog,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    L10n.of(context)!.settingUpYourTwake,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: LinagoraSysColors.material().onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: TomBootstrapDialogStyle.lottiePadding,
                    child: LottieBuilder.asset(
                      ImagePaths.lottieTwakeLoading,
                      width: TomBootstrapDialogStyle.lottieSize,
                      height: TomBootstrapDialogStyle.lottieSize,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraSysColors.material().tertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: ChatListSkeletonizerWidget()),
        ],
      ),
    );
  }
}
