import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsGroupInfoBackgroundView extends StatelessWidget {
  const ChatDetailsGroupInfoBackgroundView({
    super.key,
    required this.animationController,
  });

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            sysColor.onTertiaryContainer.withValues(
              alpha: animationController.value,
            ),
          ],
        ),
      ),
    );
  }
}
