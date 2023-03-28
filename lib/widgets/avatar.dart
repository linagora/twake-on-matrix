import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/string_color.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

import 'package:auto_size_text/auto_size_text.dart';

class Avatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  static const double defaultSize = 56;
  final Client? client;
  final double fontSize;
  final defaultGradientColorStart = const Color(0xFFBDF4A1);
  final defaultGradientColorEnd = const Color(0xFF52CE64);

  const Avatar({
    this.mxContent,
    this.name,
    this.size = defaultSize,
    this.onTap,
    this.client,
    this.fontSize = 22,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var fallbackLetters = '@';
    final name = this.name;
    if (name != null) {
      if (name.runes.length >= 2) {
        fallbackLetters = String.fromCharCodes(name.runes, 0, 2);
      } else if (name.runes.length == 1) {
        fallbackLetters = name;
      }
    }
    final noPic =
        mxContent == null || mxContent.toString().isEmpty || mxContent.toString() == 'null';
    final textWidget = Center(
      child: AutoSizeText(
          fallbackLetters.toUpperCase(),
          maxLines: 1,
          minFontSize: 8,
          maxFontSize: fontSize,
          style: TextStyle(
            color: noPic ? Colors.white : null,
            fontSize: fontSize,
            fontFamily: 'SFProRounded',
            fontWeight: FontWeight.bold,
          ),
        ),
    );  
    final borderRadius = BorderRadius.circular(size / 2);
    final container = ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: noPic ? null : Theme.of(context).secondaryHeaderColor,
        decoration: noPic
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    name?.lightColorAvatarGradientStart ?? defaultGradientColorStart,
                    name?.lightColorAvatarGradientEnd ?? defaultGradientColorEnd,
                  ],
                  stops: const [
                    0.1484,
                    0.9603,
                  ],
                ),
              )
            : null,
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
