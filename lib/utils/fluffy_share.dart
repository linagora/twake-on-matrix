import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fluffychat/utils/platform_infos.dart';

abstract class FluffyShare {
  static Future<void> share(String text, BuildContext context) async {
    if (PlatformInfos.isMobile) {
      final box = context.findRenderObject() as RenderBox;
      return Share.share(
        text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
    }
    await Clipboard.setData(
      ClipboardData(text: text),
    );
    TwakeSnackBar.show(context, L10n.of(context)!.copiedToClipboard);
    return;
  }
}
