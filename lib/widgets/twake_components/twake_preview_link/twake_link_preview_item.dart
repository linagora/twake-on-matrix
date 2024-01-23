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

  static const linkPreviewNoImageKey = ValueKey('LinkPreviewNoImageKey');

  static const linkPreviewLargeKey = ValueKey('LinkPreviewLargeKey');

  static const linkPreviewSmallKey = ValueKey('LinkPreviewSmallKey');

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(
        'ContainerKey:TwakeLinkPreviewItem${urlPreviewPresentation.description}',
      ),
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
        key: linkPreviewNoImageKey,
        urlPreviewPresentation: urlPreviewPresentation,
      );
    }

    if (urlPreviewPresentation.imageHeight! > 200) {
      return LinkPreviewLarge(
        key: linkPreviewLargeKey,
        urlPreviewPresentation: urlPreviewPresentation,
      );
    }

    return LinkPreviewSmall(
      key: linkPreviewSmallKey,
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
            key: ValueKey(
              'PaddingTitleKey:LinkPreviewNoImage${urlPreviewPresentation.title}',
            ),
            padding: TwakeLinkPreviewItemStyle.paddingTitle,
            child: Text(
              key: ValueKey(
                'TextTitleKey:LinkPreviewNoImage${urlPreviewPresentation.title}',
              ),
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
            key: ValueKey(
              'PaddingSubtitleKey:LinkPreviewNoImage${urlPreviewPresentation.description}',
            ),
            padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
            child: Text(
              key: ValueKey(
                'TextSubtitleKey:LinkPreviewNoImage${urlPreviewPresentation.description}',
              ),
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
            key: const ValueKey(
              'ClipRRectKey:LinkPreviewLarge',
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(
                TwakeLinkPreviewItemStyle.radiusBorder,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: MxcImage(
                key: ValueKey(
                  'MxcImageKey:LinkPreviewLarge${urlPreviewPresentation.imageUri}',
                ),
                uri: urlPreviewPresentation.imageUri,
                fit: BoxFit.cover,
                isThumbnail: false,
                placeholder: (_) => const SizedBox(),
              ),
            ),
          ),
        if (urlPreviewPresentation.title != null)
          Padding(
            key: ValueKey(
              'PaddingTitleKey:LinkPreviewLarge${urlPreviewPresentation.title}',
            ),
            padding: TwakeLinkPreviewItemStyle.paddingTitle,
            child: Text(
              key: ValueKey(
                'TextTitleKey:LinkPreviewLarge${urlPreviewPresentation.title}',
              ),
              urlPreviewPresentation.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (urlPreviewPresentation.description != null)
          Padding(
            key: ValueKey(
              'PaddingSubtitleKey:LinkPreviewLarge${urlPreviewPresentation.description}',
            ),
            padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
            child: Text(
              key: ValueKey(
                'TextSubtitleKey:LinkPreviewLarge${urlPreviewPresentation.description}',
              ),
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
              key: const ValueKey(
                'ClipRRectKey:LinkPreviewSmall',
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
              ),
              child: SizedBox(
                height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                child: MxcImage(
                  key: ValueKey(
                    'MxcImageKey:LinkPreviewSmall${urlPreviewPresentation.imageUri}',
                  ),
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
                  key: ValueKey(
                    'PaddingTitleKey:LinkPreviewSmall${urlPreviewPresentation.title}',
                  ),
                  padding: TwakeLinkPreviewItemStyle.paddingTitle,
                  child: Text(
                    key: ValueKey(
                      'TextTitleKey:LinkPreviewSmall${urlPreviewPresentation.title}',
                    ),
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
                  key: ValueKey(
                    'PaddingSubtitleKey:LinkPreviewSmall${urlPreviewPresentation.description}',
                  ),
                  padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                  child: Text(
                    key: ValueKey(
                      'TextSubtitleKey:LinkPreviewSmall${urlPreviewPresentation.description}',
                    ),
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
