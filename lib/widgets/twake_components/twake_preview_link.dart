import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakePreviewLink extends StatelessWidget {
  final String link;

  const TwakePreviewLink({
    Key? key,
    required this.link,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: AnyLinkPreview(
        backgroundColor: LinagoraRefColors.material().primary[95],
        previewHeight: MediaQuery.of(context).size.height * 0.35,
        link: link,
        displayDirection: UIDirection.uiDirectionVertical,
        titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.15,
              fontWeight: FontWeight.w500,
            ),
        bodyStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LinagoraRefColors.material().neutral[50],
              fontWeight: FontWeight.w400,
            ),
        removeElevation: true,
        bodyMaxLines: 4,
        borderRadius: 12,
      ),
    );
  }
}
