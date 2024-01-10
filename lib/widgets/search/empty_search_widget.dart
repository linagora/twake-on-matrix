import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/search/empty_search_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class EmptySearchWidget extends StatelessWidget {
  const EmptySearchWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EmptySearchWidgetStyle.bodyPadding,
      child: Column(
        children: [
          SvgPicture.asset(
            ImagePaths.icEmptySearch,
            width: EmptySearchWidgetStyle.iconWidth,
            height: EmptySearchWidgetStyle.iconHeight,
          ),
          Padding(
            padding: EmptySearchWidgetStyle.textPadding,
            child: Text(
              L10n.of(context)!.noResults,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: LinagoraRefColors.material().neutral[40],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
