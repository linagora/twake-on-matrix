import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeLinkPreviewItem extends StatelessWidget {
  final bool ownMessage;
  final UrlPreviewPresentation urlPreviewPresentation;
  final TextStyle? textStyle;

  const TwakeLinkPreviewItem({
    super.key,
    required this.ownMessage,
    required this.urlPreviewPresentation,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: ownMessage
            ? LinagoraRefColors.material().primary[95]
            : LinagoraStateLayer(
                LinagoraSysColors.material().surfaceTint,
              ).opacityLayer1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            TwakeLinkPreviewItemStyle.radiusBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urlPreviewPresentation.imageUri != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
                topRight: Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
              ),
              child: SizedBox(
                height:
                    TwakeLinkPreviewItemStyle.heightMxcImagePreview(context),
                width: MessageStyle.messageBubbleWidth(context),
                child: MxcImage(
                  height:
                      TwakeLinkPreviewItemStyle.heightMxcImagePreview(context),
                  width: MessageStyle.messageBubbleWidth(context),
                  uri: urlPreviewPresentation.imageUri,
                  fit: BoxFit.cover,
                  isThumbnail: false,
                  placeholder: (_) => const SizedBox(),
                ),
              ),
            ),
          if (urlPreviewPresentation.title != null)
            Padding(
              padding: TwakeLinkPreviewItemStyle.paddingAll,
              child: Text(
                urlPreviewPresentation.title!,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (urlPreviewPresentation.description != null)
            Padding(
              padding: TwakeLinkPreviewItemStyle.paddingAll,
              child: Text(
                urlPreviewPresentation.description!,
                style: textStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
