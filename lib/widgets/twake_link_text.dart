import 'package:fluffychat/widgets/clean_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:matrix_link_text/link_text.dart';

import 'twake_components/twake_preview_link.dart';

class TwakeLinkText extends StatelessWidget {
  final String text;
  final Widget childWidget;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;
  final String? firstValidUrl;

  const TwakeLinkText({
    Key? key,
    required this.text,
    required this.childWidget,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onLinkTap,
    this.maxLines,
    this.firstValidUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (firstValidUrl == null) {
      return _buildWidgetNoPreview(context);
    }

    return _buildWidgetWithPreview(context, firstValidUrl!);
  }

  Widget _buildWidgetWithPreview(BuildContext context, String url) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TwakePreviewLink(link: url),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCleanRichText(context),
          )
        ]);
  }

  Widget _buildWidgetNoPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: _buildCleanRichText(context),
    );
  }

  Widget _buildCleanRichText(BuildContext context) {
    return TwakeCleanRichText(
      text: text,
      childWidget: childWidget,
      textStyle: textStyle,
      linkStyle: linkStyle,
      textAlign: textAlign,
      onLinkTap: onLinkTap,
      maxLines: maxLines,
    );
  }
}
