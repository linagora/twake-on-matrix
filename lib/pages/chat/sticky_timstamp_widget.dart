import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class StickyTimestampWidget extends StatelessWidget {
  final String content;
  final bool isStickyHeader;

  const StickyTimestampWidget({
    Key? key,
    required this.content,
    this.isStickyHeader = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: UnconstrainedBox(
        child: Container(
          margin: const EdgeInsets.only(top: 8.0),
          decoration: isStickyHeader
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: LinagoraRefColors.material()
                      .primary[100]
                      ?.withOpacity(0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      offset: Offset(0, 1),
                      blurRadius: 80,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.15),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.25,
                    color: LinagoraRefColors.material().tertiary[20],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
