import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeLinkPreviewItem extends StatelessWidget {
  final bool ownMessage;
  final UrlPreviewPresentation urlPreviewPresentation;

  const TwakeLinkPreviewItem({
    super.key,
    required this.ownMessage,
    required this.urlPreviewPresentation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        maxHeight: double.infinity,
      ),
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
      child: _buildLinkPreview(),
    );
  }

  Widget _buildLinkPreview() {
    if (urlPreviewPresentation.imageUri == null ||
        urlPreviewPresentation.imageWidth == null ||
        urlPreviewPresentation.imageHeight == null) {
      return LinkPreviewNoImage(
        urlPreviewPresentation: urlPreviewPresentation,
      );
    }

    if (urlPreviewPresentation.imageHeight! > 200) {
      return LinkPreviewLarge(
        urlPreviewPresentation: urlPreviewPresentation,
      );
    }

    return LinkPreviewSmall(
      urlPreviewPresentation: urlPreviewPresentation,
    );
  }
}

class LinkPreviewNoImage extends StatelessWidget {
  const LinkPreviewNoImage({
    super.key,
    required this.urlPreviewPresentation,
  });

  final UrlPreviewPresentation urlPreviewPresentation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (urlPreviewPresentation.title != null)
          Padding(
            padding: TwakeLinkPreviewItemStyle.paddingTitle,
            child: Text(
              urlPreviewPresentation.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class LinkPreviewLarge extends StatelessWidget {
  const LinkPreviewLarge({
    super.key,
    required this.urlPreviewPresentation,
  });

  final UrlPreviewPresentation urlPreviewPresentation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (urlPreviewPresentation.imageUri != null)
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                TwakeLinkPreviewItemStyle.radiusBorder,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: MxcImage(
                uri: urlPreviewPresentation.imageUri,
                fit: BoxFit.cover,
                isThumbnail: false,
                placeholder: (_) => const SizedBox(),
              ),
            ),
          ),
        if (urlPreviewPresentation.title != null)
          Padding(
            padding: TwakeLinkPreviewItemStyle.paddingTitle,
            child: Text(
              urlPreviewPresentation.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class LinkPreviewSmall extends StatelessWidget {
  const LinkPreviewSmall({
    super.key,
    required this.urlPreviewPresentation,
  });

  final UrlPreviewPresentation urlPreviewPresentation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (urlPreviewPresentation.imageUri != null)
          Padding(
            padding: TwakeLinkPreviewItemStyle.paddingPreviewImage,
            child: ClipRRect(
              borderRadius: BorderRadius.all(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LinagoraRefColors.material().neutral[50],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
