import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';

class Avatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final bool keepAlive;

  const Avatar({
    this.mxContent,
    this.name,
    this.size = AvatarStyle.defaultSize,
    this.onTap,
    this.fontSize = AvatarStyle.defaultFontSize,
    this.boxShadows,
    this.textColor,
    this.keepAlive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: MxcImage(
            key: Key(mxContent.toString()),
            uri: mxContent,
            fit: BoxFit.cover,
            width: size,
            height: size,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context) * 2)
                .round(),
            cacheKey: mxContent.toString(),
            animated: true,
            isThumbnail: false,
            placeholder: (context) => _fallbackAvatar(),
            keepAlive: keepAlive,
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final fallbackLetters = name?.getShortcutNameForAvatar() ?? '@';
    return RoundAvatar(
      size: size,
      text: fallbackLetters,
      boxShadows: boxShadows,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: textColor ?? AvatarStyle.defaultTextColor(_havePicture),
        fontFamily: AvatarStyle.fontFamily,
        fontWeight: AvatarStyle.fontWeight,
      ),
    );
  }

  bool get _havePicture {
    return mxContent == null ||
        mxContent.toString().isEmpty ||
        mxContent.toString() == 'null';
  }
}
