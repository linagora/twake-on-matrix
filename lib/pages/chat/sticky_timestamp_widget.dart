import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class StickyTimestampWidget extends StatelessWidget {
  final String content;
  final bool isStickyHeader;

  const StickyTimestampWidget({
    super.key,
    required this.content,
    this.isStickyHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: UnconstrainedBox(
        child: Opacity(
          opacity: isStickyHeader ? 0.8 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: isStickyHeader
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: LinagoraRefColors.material().primary[100],
                  )
                : null,
            alignment: Alignment.center,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LinagoraRefColors.material().tertiary[20],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
