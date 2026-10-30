import 'package:twake_chat/presentation/extensions/media/url_preview_extension.dart';
import 'package:twake_chat/presentation/model/media/url_preview_presentation.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/providers/url_preview_provider.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/mxc_image.dart';
import 'package:twake_chat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TwakeLinkPreviewItem extends ConsumerStatefulWidget {
  final bool ownMessage;
  final String? previewLink;

  const TwakeLinkPreviewItem({
    super.key,
    required this.ownMessage,
    this.previewLink,
  });

  static ValueKey<String> get linkPreviewBodyKey =>
      LinkPreviewKeys.linkPreviewBody.valueKey;

  static ValueKey<String> get linkPreviewLargeKey =>
      LinkPreviewKeys.linkPreviewLarge.valueKey;

  @override
  ConsumerState<TwakeLinkPreviewItem> createState() =>
      _TwakeLinkPreviewItemState();
}

class _TwakeLinkPreviewItemState extends ConsumerState<TwakeLinkPreviewItem>
    with AutomaticKeepAliveClientMixin {
  Uri? get _previewUri {
    final link = widget.previewLink;
    if (link == null || link.trim().isEmpty) return null;
    return Uri.tryParse(link);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uri = _previewUri;
    final preview = uri == null ? null : ref.watch(urlPreviewProvider(uri));
    switch (preview) {
      case AsyncError():
        return const SizedBox.shrink();
      case AsyncData(:final value):
        return Container(
          key: TwakeLinkPreviewItem.linkPreviewBodyKey,
          constraints: const BoxConstraints(minWidth: double.infinity),
          height: TwakeLinkPreviewItemStyle.maxHeightPreviewItem,
          decoration: ShapeDecoration(
            color: widget.ownMessage
                ? LinagoraSysColors.material().primaryContainer
                : LinagoraSysColors.material().onSurface.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                TwakeLinkPreviewItemStyle.radiusBorder,
              ),
            ),
          ),
          child: LinkPreviewBuilder(
            key: TwakeLinkPreviewItem.linkPreviewLargeKey,
            urlPreviewPresentation: value.toPresentation(),
            previewLink: widget.previewLink,
          ),
        );
      default:
        return _buildSkeleton(context);
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return Skeletonizer.zone(
      child: Container(
        constraints: const BoxConstraints(minWidth: double.infinity),
        height: TwakeLinkPreviewItemStyle.maxHeightPreviewItem,
        decoration: ShapeDecoration(
          color: widget.ownMessage
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
            const Bone.button(
              width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
                bottom: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    key: LinkPreviewBuilder.paddingTitleKey,
                    padding: TwakeLinkPreviewItemStyle.paddingTitle,
                    child: Column(
                      children: [
                        Bone.text(
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TwakeLinkPreviewItemStyle.skeletonizerTextPadding,
                        Bone.text(
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    key: LinkPreviewBuilder.paddingSubtitleKey,
                    padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                    child: Column(
                      children: [
                        Bone.text(
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TwakeLinkPreviewItemStyle.skeletonizerTextPadding,
                        Bone.text(
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class LinkPreviewBuilder extends StatelessWidget {
  const LinkPreviewBuilder({
    super.key,
    required this.urlPreviewPresentation,
    this.previewLink,
  });

  final String? previewLink;

  final UrlPreviewPresentation urlPreviewPresentation;

  static ValueKey<String> get thumbnailClipKey =>
      LinkPreviewKeys.thumbnailClip.valueKey;

  static ValueKey<String> get mxcImageKey => LinkPreviewKeys.mxcImage.valueKey;

  static ValueKey<String> get paddingTitleKey =>
      LinkPreviewKeys.paddingTitle.valueKey;

  static ValueKey<String> get paddingSubtitleKey =>
      LinkPreviewKeys.paddingSubtitle.valueKey;

  static ValueKey<String> get titleKey => LinkPreviewKeys.title.valueKey;

  static ValueKey<String> get subtitleKey => LinkPreviewKeys.subtitle.valueKey;

  static ValueKey<String> get imageDefaultKey =>
      LinkPreviewKeys.imageDefault.valueKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (previewLink == null) return;
        UrlLauncher(context, url: previewLink).launchUrl();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            key: LinkPreviewBuilder.thumbnailClipKey,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
              bottom: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
            ),
            child: SizedBox(
              width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              child:
                  (urlPreviewPresentation.imageUri != null &&
                      urlPreviewPresentation.imageWidth != null &&
                      urlPreviewPresentation.imageHeight != null)
                  ? MxcImage(
                      key: LinkPreviewBuilder.mxcImageKey,
                      uri: urlPreviewPresentation.imageUri,
                      height: MediaQuery.sizeOf(context).height,
                      width: MediaQuery.sizeOf(context).width,
                      fit: BoxFit.cover,
                      isThumbnail: false,
                      placeholder: (_) => const Skeletonizer.zone(
                        child: Bone.button(
                          width:
                              TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                          height:
                              TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              TwakeLinkPreviewItemStyle.radiusBorder,
                            ),
                            bottom: Radius.circular(
                              TwakeLinkPreviewItemStyle.radiusBorder,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      key: LinkPreviewBuilder.imageDefaultKey,
                      height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                      child: const Icon(
                        Icons.link,
                        size: TwakeLinkPreviewItemStyle.linkIconSize,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  key: LinkPreviewBuilder.paddingTitleKey,
                  padding: TwakeLinkPreviewItemStyle.paddingTitle,
                  child: Text(
                    key: LinkPreviewBuilder.titleKey,
                    urlPreviewPresentation.title ?? '',
                    style: Theme.of(context)
                        .extension<LinagoraTextThemeExtension>()!
                        .titleSmall2
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  key: LinkPreviewBuilder.paddingSubtitleKey,
                  padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                  child: Text(
                    key: LinkPreviewBuilder.subtitleKey,
                    urlPreviewPresentation.description ?? '',
                    style: Theme.of(context)
                        .extension<LinagoraTextThemeExtension>()!
                        .titleSmall2
                        .copyWith(
                          color: LinagoraRefColors.material().tertiary[20],
                        ),
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
