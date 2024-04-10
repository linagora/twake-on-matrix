import 'package:fluffychat/pages/bootstrap/linear_progress_indicator_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TomBootstrapProgressItem extends StatelessWidget {
  final String titleProgress;
  final String? semanticsLabel;
  final bool isCompleted;
  final bool isProgress;

  const TomBootstrapProgressItem({
    super.key,
    required this.titleProgress,
    this.semanticsLabel,
    this.isCompleted = false,
    this.isProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: LinearProgressIndicatorStyle.indicatorPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: LinearProgressIndicatorStyle.iconPadding,
            child: Icon(
              Icons.check_circle_outline,
              size: LinearProgressIndicatorStyle.iconSize,
              color: isCompleted == true
                  ? Theme.of(context).colorScheme.primary
                  : LinagoraSysColors.material().tertiary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: LinearProgressIndicatorStyle.titlePadding,
                  child: Text(
                    titleProgress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LinagoraSysColors.material().tertiary,
                        ),
                  ),
                ),
                LinearProgressIndicator(
                  value: isProgress == true
                      ? null
                      : isCompleted
                          ? 1
                          : 0,
                  minHeight: LinearProgressIndicatorStyle.minHeightIndicator,
                  borderRadius: BorderRadius.circular(
                    LinearProgressIndicatorStyle.borderRadius,
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
