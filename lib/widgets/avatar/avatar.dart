import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';

import 'package:matrix/matrix.dart';

class Avatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  final Client? client;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final TextStyle? textStyle;

  const Avatar({
    this.mxContent,
    this.name,
    this.size = AvatarStyle.defaultSize,
    this.onTap,
    this.client,
    this.fontSize = AvatarStyle.defaultFontSize,
    this.boxShadows,
    this.textStyle,
    this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fallbackLetters = name?.getShortcutNameForAvatar() ?? '@';
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: MxcImage(
        key: Key(mxContent.toString()),
        uri: mxContent,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheKey: mxContent.toString(),
        placeholder: (context) => RoundAvatar(
          size: size,
          text: fallbackLetters,
          boxShadows: boxShadows,
          textStyle: TextStyle(
            fontSize: fontSize,
            color: textColor ?? AvatarStyle.defaultTextColor(_havePicture),
            fontFamily: AvatarStyle.fontFamily,
            fontWeight: AvatarStyle.fontWeight,
          ),
        ),
      ),
    );
  }

  bool get _havePicture {
    return mxContent == null
      || mxContent.toString().isEmpty
      || mxContent.toString() == 'null';
  }
}
