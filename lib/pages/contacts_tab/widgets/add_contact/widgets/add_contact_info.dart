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
  });

  final String title;
  final void Function(String value) onChanged;
  final String initialValue;
  final String? assetPath;
  final IconData? iconData;
  final double additionalHorizontalPadding;

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
      leadingIcon = Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: leadingIcon,
        ),
      );
    } else {
      leadingIcon = const SizedBox();
    }

    final title = Text(
      widget.title,
      style: textTheme.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        color: LinagoraRefColors.material().neutral,
      ),
    );

    final textField = TextField(
      controller: _textController,
      onChanged: widget.onChanged,
      style: textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        height: 24 / 17,
        color: LinagoraRefColors.material().neutral[10],
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
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
          padding: EdgeInsets.symmetric(
            horizontal: 8 + widget.additionalHorizontalPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              leadingIcon,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      textField,
                    ],
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
}
