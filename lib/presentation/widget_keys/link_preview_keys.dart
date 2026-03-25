import 'package:flutter/foundation.dart';

enum LinkPreviewKeys {
  linkPreviewBody,
  linkPreviewLarge,
  clipRRect,
  mxcImage,
  paddingTitle,
  paddingSubtitle,
  title,
  subtitle,
  imageDefault,
  twakeLinkView,
  twakeLinkPreviewItem;

  Key get key => Key('linkPreview.$name');

  ValueKey<String> get valueKey => ValueKey('linkPreview.$name');
}
