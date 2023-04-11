import 'package:fluffychat/widgets/twake_components/twake_fab/twake_fab_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TwakeFloatingButton extends StatelessWidget {
  const TwakeFloatingButton({
    Key? key,
    required this.svgString,
    this.svgWidth = TwakeFabStyle.defaultSize,
    this.svgHeight = TwakeFabStyle.defaultSize,
    this.svgColor = TwakeFabStyle.defaultPrimaryColor,
    this.textStyle,
    required this.buttonText,
    this.isSelected = false,
    this.notificationCount = 0,
    this.onTap,
  }) : super(key: key);
  final String svgString;
  final double svgWidth;
  final double svgHeight;
  final Color svgColor;
  final TextStyle? textStyle;
  final String buttonText;
  final bool isSelected;
  final int notificationCount;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 5.0),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: svgWidth + TwakeFabStyle.notificationBubbleWidth,
                ),
                SvgPicture.asset(
                  svgString,
                  fit: BoxFit.fitHeight,
                  color: svgColor,
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: TwakeFabStyle.notificationBubbleWidth,
                      height: TwakeFabStyle.notificationBubbleHeight,
                      decoration: BoxDecoration(
                        color: TwakeFabStyle.notificationBubbleBackgroundColor,
                        borderRadius: TwakeFabStyle.notificationBubbleBorderRadius,
                        border: TwakeFabStyle.notificationBubbleBorder(context),
                      ),
                      child: Center(
                        child: Text(
                          notificationCount.toString(),
                          style: TwakeFabStyle.notificationBubbleTextStyle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              buttonText,
              style: textStyle ?? TwakeFabStyle.buttonTextStyle(context, isSelected),
            ),
          ),
        ],
      ),
    );
  }
}
