import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/presentation/extensions/media/url_preview_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mixins/get_preview_url_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix_link_text/link_text.dart';

class TwakeLinkPreview extends StatefulWidget {
  final Uri uri;
  final int? preferredPointInTime;
  final String text;
  final Widget childWidget;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;
  final double? fontSize;
  final bool ownMessage;
  final TextSpanBuilder? textSpanBuilder;

  const TwakeLinkPreview({
    super.key,
    required this.uri,
    this.preferredPointInTime,
    required this.text,
    required this.childWidget,
    required this.ownMessage,
    this.textStyle,
    this.linkStyle,
    this.textAlign,
    this.onLinkTap,
    this.maxLines,
    this.fontSize,
    this.textSpanBuilder,
  });

  @override
  State<TwakeLinkPreview> createState() => TwakeLinkPreviewController();
}

class TwakeLinkPreviewController extends State<TwakeLinkPreview>
    with GetPreviewUrlMixin {
  String? get firstValidUrl => widget.text.getFirstValidUrl();

  @override
  String debugLabel = 'TwakeLinkPreviewController';

  @override
  void initState() {
    if (firstValidUrl != null) {
      getPreviewUrl(uri: widget.uri);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TwakeLinkView(
      text: widget.text,
      textStyle: widget.textStyle,
      linkStyle: widget.linkStyle,
      childWidget: widget.childWidget,
      firstValidUrl: firstValidUrl,
      onLinkTap: (url) => UrlLauncher(context, url.toString()).launchUrl(),
      textSpanBuilder: widget.textSpanBuilder,
      previewItemWidget: ValueListenableBuilder(
        valueListenable: getPreviewUrlStateNotifier,
        builder: (context, state, _) {
          return state.fold(
            (failure) => const SizedBox.shrink(),
            (success) {
              if (success is GetPreviewUrlSuccess) {
                final previewLink = success.urlPreview.toPresentation();
                return TwakeLinkPreviewItem(
                  ownMessage: widget.ownMessage,
                  urlPreviewPresentation: previewLink,
                );
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }
}
