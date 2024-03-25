import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view_style.dart';
import 'package:flutter/material.dart';

class TwakeLinkView extends StatelessWidget {
  final String text;
  final Widget messageContentWidget;
  final Widget previewItemWidget;
  final String? firstValidUrl;

  const TwakeLinkView({
    Key? key,
    required this.text,
    required this.messageContentWidget,
    required this.previewItemWidget,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        previewItemWidget,
        const SizedBox(height: 2),
        Padding(
          padding: TwakeLinkViewStyle.paddingWidgetNoPreview,
          child: messageContentWidget,
        ),
      ],
    );
  }

  Widget _buildWidgetNoPreview(BuildContext context) {
    return Padding(
      padding: TwakeLinkViewStyle.paddingWidgetNoPreview,
      child: messageContentWidget,
    );
  }
}
