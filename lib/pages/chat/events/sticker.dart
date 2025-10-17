import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

import '../../../config/app_config.dart';
import 'images_builder/image_bubble.dart';

class Sticker extends StatefulWidget {
  final Event event;

  const Sticker(this.event, {super.key});

  @override
  StickerState createState() => StickerState();
}

class StickerState extends State<Sticker> {
  bool? animated;

  @override
  Widget build(BuildContext context) {
    return ImageBubble(
      widget.event,
      width: 400,
      height: 400,
      fit: BoxFit.contain,
      onTapPreview: () {
        setState(() => animated = true);
        showOkAlertDialog(
          context: context,
          message: widget.event.body,
          okLabel: L10n.of(context)!.ok,
        );
      },
      animated: animated ?? AppConfig.autoplayImages,
    );
  }
}
