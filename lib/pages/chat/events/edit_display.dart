import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/edit_content.dart';
import 'package:fluffychat/pages/chat/events/edit_display_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class EditDisplay extends StatelessWidget {
  final ValueNotifier<Event?>? editEventNotifier;
  final void Function()? onCloseEditAction;
  final Timeline? timeline;

  EditDisplay({
    super.key,
    this.editEventNotifier,
    this.onCloseEditAction,
    this.timeline,
  });

  final responsive = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TwakeThemes.animationDuration,
      curve: TwakeThemes.animationCurve,
      height: EditDisplayStyle.replyContainerHeight,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (responsive.isMobile(context))
            Padding(
              padding: EditDisplayStyle.editIconPadding,
              child: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).primaryColor,
              ),
            ),
          Expanded(
            child: EditContent(
              editEvent: editEventNotifier!.value!,
              timeline: timeline,
            ),
          ),
          if (responsive.isMobile(context))
            Padding(
              padding: EditDisplayStyle.iconClosePadding,
              child: IconButton(
                tooltip: L10n.of(context)!.close,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onPressedAction,
              ),
            ),
        ],
      ),
    );
  }

  void onPressedAction() {
    if (editEventNotifier?.value != null) {
      onCloseEditAction?.call();
      return;
    }
  }
}
