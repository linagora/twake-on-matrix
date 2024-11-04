import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';

mixin LinkifyMixin {
  void handleOnTappedLinkHtml({
    required BuildContext context,
    required Link link,
  }) {
    Logs().i('LinkifyMixin: handleOnTappedLink: link: $link');
    switch (link.type) {
      case LinkType.url:
        UrlLauncher(context, url: link.value.toString()).launchUrl();
        break;
      case LinkType.phone:
        break;
      default:
        Logs().i('LinkifyMixin: handleOnTappedLink: Unhandled link: $link');
        break;
    }
  }
}
