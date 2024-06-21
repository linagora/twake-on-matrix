import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/widgets/mxc_image.dart';

class TwakeAvatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  static const double defaultSize = 44;
  final Client? client;
  final double fontSize;

  const TwakeAvatar({
    this.mxContent,
    this.name,
    this.size = defaultSize,
    this.onTap,
    this.client,
    this.fontSize = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var fallbackLetters = '@';
    final name = this.name;
    if (name != null) {
      fallbackLetters = name[0];
    }

    final noPic = mxContent == null ||
        mxContent.toString().isEmpty ||
        mxContent.toString() == 'null';
    final textWidget = Center(
      child: Text(
        fallbackLetters,
        style: TextStyle(
          color: noPic
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              : null,
          fontSize: fontSize,
        ),
      ),
    );
    final borderRadius = BorderRadius.circular(12.0);
    final container = ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x222c2d2f)
              : Colors.transparent,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xeee4e4e4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: noPic
            ? textWidget
            : MxcImage(
                key: Key(mxContent.toString()),
                uri: mxContent,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_) => textWidget,
                cacheKey: mxContent.toString(),
              ),
      ),
    );
    if (onTap == null) return container;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: container,
    );
  }
}
