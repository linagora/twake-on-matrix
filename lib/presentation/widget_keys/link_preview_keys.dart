import 'package:flutter/foundation.dart';

enum LinkPreviewKeys {
  linkPreviewBody(
    Key('linkPreview.linkPreviewBody'),
    ValueKey('linkPreview.linkPreviewBody'),
  ),
  linkPreviewLarge(
    Key('linkPreview.linkPreviewLarge'),
    ValueKey('linkPreview.linkPreviewLarge'),
  ),
  thumbnailClip(
    Key('linkPreview.thumbnailClip'),
    ValueKey('linkPreview.thumbnailClip'),
  ),
  mxcImage(
    Key('linkPreview.mxcImage'),
    ValueKey('linkPreview.mxcImage'),
  ),
  paddingTitle(
    Key('linkPreview.paddingTitle'),
    ValueKey('linkPreview.paddingTitle'),
  ),
  paddingSubtitle(
    Key('linkPreview.paddingSubtitle'),
    ValueKey('linkPreview.paddingSubtitle'),
  ),
  title(
    Key('linkPreview.title'),
    ValueKey('linkPreview.title'),
  ),
  subtitle(
    Key('linkPreview.subtitle'),
    ValueKey('linkPreview.subtitle'),
  ),
  imageDefault(
    Key('linkPreview.imageDefault'),
    ValueKey('linkPreview.imageDefault'),
  ),
  twakeLinkView(
    Key('linkPreview.twakeLinkView'),
    ValueKey('linkPreview.twakeLinkView'),
  ),
  twakeLinkPreviewItem(
    Key('linkPreview.twakeLinkPreviewItem'),
    ValueKey('linkPreview.twakeLinkPreviewItem'),
  );

  const LinkPreviewKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
