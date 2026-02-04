import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsGroupDescriptionView extends StatefulWidget {
  const ChatDetailsGroupDescriptionView({
    super.key,
    required this.topic,
    required this.onHeightCalculated,
  });

  final String topic;
  final void Function(double height) onHeightCalculated;

  @override
  State<ChatDetailsGroupDescriptionView> createState() =>
      _ChatDetailsGroupDescriptionViewState();
}

class _ChatDetailsGroupDescriptionViewState
    extends State<ChatDetailsGroupDescriptionView> {
  final key = GlobalKey();
  late final LinagoraSysColors sysColors;
  late final LinagoraRefColors refColors;
  String description = '';

  void calculateHeight() {
    if (!mounted) return;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      widget.onHeightCalculated(renderBox.size.height);
    }
  }

  @override
  void initState() {
    super.initState();
    sysColors = LinagoraSysColors.material();
    refColors = LinagoraRefColors.material();
    description = widget.topic.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateHeight();
    });
  }

  @override
  void didUpdateWidget(ChatDetailsGroupDescriptionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic) {
      setState(() {
        description = widget.topic.trim();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        calculateHeight();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final displayText = description.isEmpty ? l10n.noDescription : description;

    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sysColors.onPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.description,
            style: textTheme.labelMedium?.copyWith(
              color: refColors.neutral[40],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: textTheme.labelMedium?.copyWith(
              color: refColors.tertiary[20],
            ),
          ),
        ],
      ),
    );
  }
}
