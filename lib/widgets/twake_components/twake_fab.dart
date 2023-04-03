import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TwakeFloatingButton extends StatelessWidget {
  const TwakeFloatingButton({
    Key? key,
    required this.svgString,
    this.svgWidth = 28,
    this.svgHeight = 28,
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
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 25,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xffff3347),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : const Color.fromARGB(239, 36, 36, 36),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          notificationCount.toString(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              buttonText,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
