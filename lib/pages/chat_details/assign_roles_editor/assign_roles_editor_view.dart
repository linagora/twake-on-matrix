import 'package:fluffychat/pages/chat_details/assign_roles_editor/assign_roles_editor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_editor/assign_roles_editor_style.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/expandable_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AssignRolesEditorView extends StatelessWidget {
  final AssignRolesEditorController controller;

  const AssignRolesEditorView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.assignRoles,
        centerTitle: true,
        withDivider: true,
        context: context,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.arrow_back_ios,
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    selectedUsersListMobile(context),
                    Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        L10n.of(context)!.selectRole,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: LinagoraRefColors.material().neutral[40],
                            ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return ExpandableWidget(
                          parentWidget: Row(
                            children: [
                              Container(
                                width:
                                    AssignRolesEditorStyle.assignRoleIconSize,
                                height:
                                    AssignRolesEditorStyle.assignRoleIconSize,
                                decoration: BoxDecoration(
                                  color: controller.colorBackgroundForRoles(
                                    controller.assignRoles[index],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AssignRolesEditorStyle.assignRoleIconSize /
                                        2,
                                  ),
                                ),
                                child: Center(
                                  child: controller.iconForRoles(
                                    controller.assignRoles[index],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.assignRoles[index]
                                          .displayName(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: LinagoraSysColors.material()
                                                .onSurface,
                                          ),
                                    ),
                                    Text(
                                      controller.subtitleForRoles(
                                        controller.assignRoles[index],
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: LinagoraRefColors.material()
                                                .tertiary[20],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                shape: const CircleBorder(),
                                value: false,
                                onChanged: (value) {},
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: controller.assignRoles.length,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget selectedUsersListMobile(BuildContext context) {
    if (!controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }

    final users = controller.widget.assignedUsers;

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    return AnimatedSize(
      curve: Curves.easeIn,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8,
            bottom: 8,
          ),
          child: Wrap(
            spacing: 8.0,
            children: users.map((member) {
              return Container(
                decoration: BoxDecoration(
                  color: LinagoraStateLayer(
                    LinagoraSysColors.material().surfaceTint,
                  ).opacityLayer3,
                  borderRadius: BorderRadius.circular(
                    AssignRolesEditorStyle.avatarChipSize,
                  ),
                ),
                margin: AssignRolesEditorStyle.chipMargin,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Avatar(
                      mxContent: member.avatarUrl,
                      name: member.calcDisplayname(),
                      size: AssignRolesEditorStyle.avatarChipSize,
                    ),
                    const SizedBox(width: 4.0),
                    Padding(
                      padding: AssignRolesEditorStyle.textChipPadding,
                      child: Text(
                        member.calcDisplayname(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: LinagoraSysColors.material().onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
