import 'dart:typed_data';

import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class SendingImageWidget extends StatelessWidget {
  SendingImageWidget({
    super.key,
    required this.sendingImageData,
    required this.event,
  });

  final Uint8List sendingImageData;

  final Event event;

  final ValueNotifier<double> sendingFileProgressNotifier = ValueNotifier(0); 

  @override
  Widget build(BuildContext context) {
    if (event.status == EventStatus.sent || event.status == EventStatus.synced) {
      sendingFileProgressNotifier.value = 1;
    }

    return ValueListenableBuilder<double>(
      key: ValueKey(event.eventId),
      valueListenable: sendingFileProgressNotifier,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (sendingFileProgressNotifier.value != 1)... [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: LinagoraRefColors.material().primary[100],
              ),
              Icon(Icons.close, color: LinagoraRefColors.material().primary[100]), 
            ]
          ],
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.memory(
          sendingImageData,
          width: MessageContentStyle.imageBubbleWidth,
          height: MessageContentStyle.imageBubbleHeight,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}