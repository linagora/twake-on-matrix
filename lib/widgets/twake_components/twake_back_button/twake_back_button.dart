import 'package:fluffychat/widgets/twake_components/twake_back_button/twake_back_button_style.dart';
import 'package:flutter/material.dart';

class TwakeBackButton extends StatelessWidget {
  const TwakeBackButton({Key? key, this.color, this.onPressed }) : super(key: key);

  final Color? color;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: TwakeBackButtonStyle.backIcon,
      iconSize: TwakeBackButtonStyle.backIconSize,
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}