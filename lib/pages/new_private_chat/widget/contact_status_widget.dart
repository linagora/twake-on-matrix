import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ContactStatusWidget extends StatelessWidget {
  final ContactStatus status;

  ContactStatusWidget({
    super.key,
    required this.status,
  });

  final Color activeColor = const Color(0xFF43A843);
  final Color? inactiveColor = LinagoraRefColors.material().neutral[60];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            ImagePaths.icStatus,
            // ignore: deprecated_member_use
            color: status == ContactStatus.active ? activeColor : inactiveColor,
          ),
          status == ContactStatus.active
              ? Text(
                  " ${L10n.of(context)!.active}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: activeColor,
                      ),
                )
              : Text(
                  " ${L10n.of(context)!.inactive}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: inactiveColor,
                      ),
                ),
        ],
      ),
    );
  }
}
