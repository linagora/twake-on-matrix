import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class AddContactInfo extends StatefulWidget {
  const AddContactInfo({
    super.key,
    required this.title,
    required this.onChanged,
    this.initialValue = '',
    this.assetPath,
    this.iconData,
    this.additionalHorizontalPadding = 0,
    this.errorMessage,
    this.autoFocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.hintText,
  });

  final String title;
  final void Function(String value) onChanged;
  final String initialValue;
  final String? assetPath;
  final IconData? iconData;
  final double additionalHorizontalPadding;
  final String? errorMessage;
  final bool autoFocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? hintText;

  @override
  State<AddContactInfo> createState() => _AddContactInfoState();
}

class _AddContactInfoState extends State<AddContactInfo> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget? leadingIcon;

    if (widget.iconData != null) {
      leadingIcon = Icon(
        widget.iconData,
        size: 24,
        color: LinagoraRefColors.material().tertiary[30],
      );
    } else if (widget.assetPath != null) {
      leadingIcon = SvgPicture.asset(
        widget.assetPath!,
        width: 24,
        height: 24,
        color: LinagoraRefColors.material().tertiary[30],
      );
    }
    if (leadingIcon != null) {
      if (PlatformInfos.isMobile) {
        leadingIcon = Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: leadingIcon,
        );
      }
      leadingIcon = Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: leadingIcon,
      );
    } else {
      leadingIcon = const SizedBox();
    }

    Widget title = Text(
      widget.title,
      style: textTheme.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        color: LinagoraRefColors.material().neutral,
      ),
    );

    if (!PlatformInfos.isMobile) {
      title = Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
        child: title,
      );
    }

    final textField = TextField(
      controller: _textController,
      onChanged: widget.onChanged,
      autofocus: widget.autoFocus,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      style: textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        height: 24 / 17,
        color: LinagoraRefColors.material().neutral[10],
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        errorText: widget.errorMessage,
        hintText: widget.hintText,
        hintStyle: textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          height: 24 / 17,
          color: LinagoraRefColors.material().tertiary[30],
        ),
      ),
    );

    final divider = Divider(
      color: LinagoraSysColors.material().surfaceTint.withValues(alpha: 0.16),
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 40,
    );

    return Column(
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: leadingIconVerticalAlignment,
            children: [
              leadingIcon,
              Expanded(
                child: Padding(
                  padding: textfieldPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, textField],
                  ),
                ),
              ),
            ],
          ),
        ),
        divider,
      ],
    );
  }

  EdgeInsetsGeometry get padding {
    if (PlatformInfos.isMobile) {
      return EdgeInsets.symmetric(
        horizontal: 8 + widget.additionalHorizontalPadding,
        vertical: 8,
      );
    }

    return const EdgeInsets.fromLTRB(16, 16, 16, 0);
  }

  CrossAxisAlignment get leadingIconVerticalAlignment {
    if (PlatformInfos.isMobile) {
      return CrossAxisAlignment.center;
    }

    return CrossAxisAlignment.start;
  }

  EdgeInsetsGeometry get textfieldPadding {
    if (PlatformInfos.isMobile) {
      return const EdgeInsets.symmetric(vertical: 4);
    }

    return const EdgeInsets.only(bottom: 16);
  }
}
