import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:fluffychat/presentation/extensions/settings/user_info_visibility_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsContactsVisibilityView extends StatelessWidget {
  final SettingsContactsVisibilityController controller;

  const SettingsContactsVisibilityView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.contactsVisibility,
        centerTitle: true,
        withDivider: true,
        context: context,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: controller.onBack,
          icon: Icons.arrow_back_ios,
        ),
      ),
      body: MaxWidthBody(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      right: 32,
                      top: 24,
                      bottom: 16,
                    ),
                    child: Text(
                      L10n.of(context)!.whoCanSeeMyPhoneEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LinagoraSysColors.material().tertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            LinagoraRefColors.material().neutral[90] ??
                            Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: controller.visibilityOptions
                          .map(
                            (option) => ValueListenableBuilder(
                              valueListenable:
                                  controller.getUserInfoVisibilityNotifier,
                              builder: (context, state, _) {
                                return ValueListenableBuilder(
                                  valueListenable: controller
                                      .selectedVisibilityOptionNotifier,
                                  builder: (context, _, __) {
                                    final isVisibilitySelected =
                                        controller
                                            .selectedVisibilityOptionNotifier
                                            .value ==
                                        option;
                                    return _buildVisibilityOptionItem(
                                      context: context,
                                      option: option,
                                      enableDivider: option.enableDivider(),
                                      isSelected: isVisibilitySelected,
                                      onTap:
                                          controller.onSelectVisibilityOption,
                                    );
                                  },
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable:
                        controller.selectedVisibilityOptionNotifier,
                    builder: (context, selectedOption, _) {
                      if (selectedOption ==
                          SettingsContactsVisibilityEnum.private) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 32,
                              top: 32,
                              bottom: 8,
                            ),
                            child: Text(
                              L10n.of(
                                context,
                              )!.chooseWhichDetailsAreVisibleToOtherUsers,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().tertiary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    LinagoraRefColors.material().neutral[90] ??
                                    Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: controller.visibleFieldsOptions
                                  .map(
                                    (option) => ValueListenableBuilder(
                                      valueListenable: controller
                                          .getUserInfoVisibilityNotifier,
                                      builder: (context, state, _) {
                                        return ValueListenableBuilder(
                                          valueListenable: controller
                                              .selectedVisibleFieldNotifier,
                                          builder:
                                              (context, selectedFields, child) {
                                                return _buildVisibleFieldItem(
                                                  context: context,
                                                  option: option,
                                                  enableDivider: option
                                                      .enableDivider(),
                                                  isSelected: selectedFields
                                                      .contains(option),
                                                  onTap: controller
                                                      .onUpdateVisibleFields,
                                                );
                                              },
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius? _buildVisibilityOptionBorderRadius({
    required SettingsContactsVisibilityEnum option,
  }) {
    switch (option) {
      case SettingsContactsVisibilityEnum.public:
        return const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        );
      case SettingsContactsVisibilityEnum.contacts:
        return null;
      case SettingsContactsVisibilityEnum.private:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
    }
  }

  Widget _buildVisibilityOptionItem({
    required BuildContext context,
    required SettingsContactsVisibilityEnum option,
    void Function(SettingsContactsVisibilityEnum)? onTap,
    bool enableDivider = true,
    bool isSelected = false,
  }) {
    return InkWell(
      key: Key('visibility_option_${option.name}'),
      onTap: () => onTap?.call(option),
      borderRadius: _buildVisibilityOptionBorderRadius(option: option),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    option.title(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (enableDivider)
                  Divider(
                    height: 1,
                    color: LinagoraRefColors.material().neutral[90],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: isSelected
                  ? Icon(
                      key: Key('visibility_option_selected_${option.name}'),
                      Icons.check,
                      color: LinagoraSysColors.material().primary,
                      size: 24,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius? _buildVisibleFieldBorderRadius({required VisibleEnum option}) {
    switch (option) {
      case VisibleEnum.phone:
        return const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        );
      case VisibleEnum.email:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
    }
  }

  Widget _buildVisibleFieldItem({
    required BuildContext context,
    required VisibleEnum option,
    void Function(VisibleEnum)? onTap,
    bool enableDivider = true,
    bool isSelected = false,
  }) {
    return InkWell(
      key: Key('visible_field_option_${option.name}'),
      onTap: () => onTap?.call(option),
      borderRadius: _buildVisibleFieldBorderRadius(option: option),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: LinagoraSysColors.material().onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        option.subtitle(context),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: LinagoraSysColors.material().tertiary,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                if (enableDivider)
                  Divider(
                    height: 1,
                    color: LinagoraRefColors.material().neutral[90],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: isSelected
                  ? Icon(
                      key: Key('visible_field_option_selected_${option.name}'),
                      Icons.check,
                      color: LinagoraSysColors.material().primary,
                      size: 24,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
