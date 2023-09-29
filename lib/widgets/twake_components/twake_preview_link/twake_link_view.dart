import 'package:fluffychat/widgets/clean_rich_text.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix_link_text/link_text.dart';

class TwakeLinkView extends StatelessWidget {
  final String text;
  final Widget childWidget;
  final Widget previewItemWidget;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;
  final String? firstValidUrl;
  final TextSpanBuilder? textSpanBuilder;

  const TwakeLinkView({
    Key? key,
    required this.text,
    required this.childWidget,
    required this.previewItemWidget,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onLinkTap,
    this.maxLines,
    this.firstValidUrl,
    this.textSpanBuilder,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        previewItemWidget,
        const SizedBox(height: 2),
        _buildCleanRichText(context)
      ],
    );
  }

  Widget _buildWidgetNoPreview(BuildContext context) {
    return Padding(
      padding: TwakeLinkViewStyle.paddingWidgetNoPreview,
      child: _buildCleanRichText(context),
    );
  }

  Widget _buildCleanRichText(BuildContext context) {
    return TwakeCleanRichText(
      text: text,
      childWidget: childWidget,
      textStyle: textStyle,
      linkStyle: linkStyle,
      textAlign: textAlign ?? TextAlign.start,
      onLinkTap: onLinkTap,
      maxLines: maxLines,
      textSpanBuilder: textSpanBuilder,
    );
  }
}
