import 'dart:typed_data';

import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:flutter/material.dart';

class SendingImageWidget extends StatelessWidget {
  const SendingImageWidget({
    super.key,
    required this.sendingImageData,
  });

  final Uint8List sendingImageData;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Image.memory(
        sendingImageData,
        width: MessageContentStyle.imageBubbleWidth,
        height: MessageContentStyle.imageBubbleHeight,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}