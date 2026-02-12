import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatReportMessageAdditionalReasonDialog extends StatefulWidget {
  const ChatReportMessageAdditionalReasonDialog({
    super.key,
    required this.l10n,
    required this.isMobile,
    required this.onCommentReport,
    required this.onBack,
  });

  final L10n l10n;
  final bool isMobile;
  final void Function(String comment) onCommentReport;
  final VoidCallback onBack;

  @override
  State<ChatReportMessageAdditionalReasonDialog> createState() =>
      _ChatReportMessageAdditionalReasonDialogState();
}

class _ChatReportMessageAdditionalReasonDialogState
    extends State<ChatReportMessageAdditionalReasonDialog> {
  final controller = TextEditingController();
  final characterCount = ValueNotifier<int>(0);

  void onControllerTextChanged() {
    characterCount.value = controller.text.length;
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(onControllerTextChanged);
  }

  @override
  void dispose() {
    controller.removeListener(onControllerTextChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final materialRefsColors = LinagoraRefColors.material();
    Widget body = const SizedBox();

    final dialogDecoration = BoxDecoration(
      color: materialRefsColors.primary[100],
      borderRadius: BorderRadius.all(
        Radius.circular(widget.isMobile ? 24 : 16),
      ),
      boxShadow: [
        BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: 3,
          color: materialRefsColors.primary[0]!.withValues(alpha: 0.15),
        ),
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 3,
          color: materialRefsColors.primary[0]!.withValues(alpha: 0.30),
        ),
      ],
    );

    final backButton = IconButton(
      onPressed: widget.onBack,
      padding: widget.isMobile
          ? const EdgeInsetsDirectional.all(12)
          : EdgeInsets.zero,
      icon: const Icon(Icons.arrow_back),
    );

    final titleWidget = Text(
      widget.l10n.other,
      textAlign: TextAlign.center,
      style: widget.isMobile
          ? textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 24 / 17,
              fontWeight: FontWeight.w600,
              color: materialRefsColors.neutral[10],
            )
          : textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              height: 32 / 24,
              letterSpacing: 0,
              color: materialRefsColors.neutral[10],
            ),
    );

    final commentTextField = Stack(
      children: [
        Container(
          margin: const EdgeInsetsDirectional.only(top: 8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: LinagoraSysColors.material().outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: widget.l10n.addComment,
              hintStyle: textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 24 / 17,
                color: materialRefsColors.tertiary[50],
              ),
              counterText: '',
            ),
            maxLength: 512,
          ),
        ),
        Positioned(
          left: 12,
          child: Container(
            color: materialRefsColors.primary[100],
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: ValueListenableBuilder(
              valueListenable: characterCount,
              builder: (context, count, child) => Text(
                '${512 - count}',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  color: materialRefsColors.neutral[10],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final sendReportButton = Material(
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: () => widget.onCommentReport(controller.text),
        child: Container(
          width: widget.isMobile ? 160 : 193,
          padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: LinagoraSysColors.material().primary,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.l10n.sendReport,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: materialRefsColors.primary[100],
            ),
          ),
        ),
      ),
    );

    if (widget.isMobile) {
      body = Container(
        decoration: dialogDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 0,
                    child: titleWidget,
                  ),
                  backButton,
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
              child: commentTextField,
            ),
            const SizedBox(height: 32),
            sendReportButton,
            const SizedBox(height: 14),
          ],
        ),
      );
    } else {
      body = Container(
        padding: const EdgeInsetsDirectional.all(16),
        decoration: dialogDecoration,
        constraints: const BoxConstraints(maxWidth: 448),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 88,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(left: 8, top: 8, right: 8, child: titleWidget),
                  backButton,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              child: commentTextField,
            ),
            const SizedBox(height: 80),
            sendReportButton,
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: widget.isMobile
          ? const EdgeInsets.symmetric(horizontal: 24)
          : EdgeInsets.zero,
      child: body,
    );
  }
}
