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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (urlPreviewPresentation.imageUri != null)
            ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
              ),
              child: SizedBox(
                height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                child: MxcImage(
                  height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                  width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                  uri: urlPreviewPresentation.imageUri,
                  fit: BoxFit.cover,
                  isThumbnail: false,
                  placeholder: (_) => const SizedBox(),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urlPreviewPresentation.title != null)
                  Padding(
                    padding: TwakeLinkPreviewItemStyle.paddingTitle,
                    child: Text(
                      urlPreviewPresentation.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (urlPreviewPresentation.description != null)
                  Padding(
                    padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                    child: Text(
                      urlPreviewPresentation.description!,
                      style:
                          textStyle ?? Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
