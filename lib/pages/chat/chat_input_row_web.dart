import 'package:animations/animations.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/events/edit_display.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

typedef OnTapMoreBtnAction = void Function();
typedef OnTapEmojiAction = void Function(TapDownDetails details);

class ChatInputRowWeb extends StatelessWidget {
  ChatInputRowWeb({
    super.key,
    required this.inputBar,
    required this.onTapMoreBtn,
    required this.onEmojiAction,
    this.editEventNotifier,
    this.onCloseEditAction,
    this.timeline,
  });

  final Widget inputBar;
  final OnTapMoreBtnAction onTapMoreBtn;
  final OnTapEmojiAction onEmojiAction;
  final ValueNotifier<Event?>? editEventNotifier;
  final void Function()? onCloseEditAction;
  final Timeline? timeline;

  final responsive = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
        color: LinagoraSysColors.material().onPrimary,
        border: Border.all(
          color: LinagoraRefColors.material().tertiary,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              ValueListenableBuilder(
                valueListenable:
                    editEventNotifier ?? ValueNotifier<Event?>(null),
                builder: (context, editEvent, _) {
                  if (responsive.isMobile(context)) {
                    return const SizedBox.shrink();
                  }
                  if (editEvent == null) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: responsive.isMobile(context) ? 0 : 10,
                          ),
                          child: EditDisplay(
                            editEventNotifier: editEventNotifier,
                            onCloseEditAction: onCloseEditAction,
                            timeline:
                                timeline, // Assuming no timeline is provided
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TwakeIconButton(
                          iconColor: LinagoraSysColors.material().primary,
                          paddingAll:
                              ChatInputRowStyle.chatInputRowPaddingBtnWeb,
                          tooltip: L10n.of(context)!.close,
                          onTapDown: (details) => onCloseEditAction?.call(),
                          icon: Icons.close,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TwakeIconButton(
                    tooltip: L10n.of(context)!.more,
                    paddingAll: 0.0,
                    margin: const EdgeInsets.all(10.0),
                    iconColor: LinagoraSysColors.material().tertiary,
                    icon: Icons.add_circle_outline,
                    size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                    onTap: onTapMoreBtn,
                  ),
                  Expanded(child: inputBar),
                  InkWell(
                    onTapDown: onEmojiAction,
                    hoverColor: Colors.transparent,
                    child: PageTransitionSwitcher(
                      transitionBuilder:
                          (
                            Widget child,
                            Animation<double> primaryAnimation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return SharedAxisTransition(
                              animation: primaryAnimation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType: SharedAxisTransitionType.scaled,
                              fillColor: Colors.transparent,
                              child: child,
                            );
                          },
                      child: TwakeIconButton(
                        iconColor: LinagoraSysColors.material().tertiary,
                        paddingAll: ChatInputRowStyle.chatInputRowPaddingBtnWeb,
                        tooltip: L10n.of(context)!.emojis,
                        onTapDown: (details) => onEmojiAction.call(details),
                        icon: Icons.tag_faces,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
