import 'package:fluffychat/widgets/twake_components/twake_fab/twake_fab_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TwakeFloatingButton extends StatelessWidget {
  const TwakeFloatingButton({
    Key? key,
    required this.svgString,
    this.svgWidth = TwakeFabStyle.defaultSize,
    this.svgHeight = TwakeFabStyle.defaultSize,
    required this.buttonText,
    this.isSelected = false,
    this.notificationCount = 0,
    this.onTap,
  }) : super(key: key);
  final String svgString;
  final double svgWidth;
  final double svgHeight;
  final String buttonText;
  final bool isSelected;
  final int notificationCount;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () => {},
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: svgWidth + 20,
                  height: svgHeight + 8,
                ),
                SvgPicture.asset(
                  svgString,
                  width: svgWidth,
                  height: svgHeight,
                  color: TwakeFabStyle.iconColor(context, isSelected),
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
            Text(
              buttonText,
              style: TwakeFabStyle.buttonTextStyle(context, isSelected),
            ),
          ],
        ),
      ),
    );
  }
}
