import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat_details/chat_details_page_view/links/chat_details_links_item.dart';
import 'package:twake_chat/presentation/widget_keys/link_preview_keys.dart';

import '../base/core_robot.dart';

class LinkPreviewRobot extends CoreRobot {
  LinkPreviewRobot(super.$);

  PatrolFinder _message(String url) =>
      $(Message).containing(find.textContaining(url, findRichText: true));

  PatrolFinder timelinePreview(String url) =>
      _message(url).$(find.byKey(LinkPreviewKeys.linkPreviewBody.valueKey));

  /// Loading and success both render a box; only a failed preview is empty.
  PatrolFinder failedTimelinePreview(String url) => _message(url).$(
    find.byElementPredicate(
      (element) =>
          element.widget.key == LinkPreviewKeys.twakeLinkPreviewItem.valueKey &&
          element.size?.height == 0,
    ),
  );

  String? timelinePreviewTitle(String url) =>
      timelinePreview(url).$(find.byKey(LinkPreviewKeys.title.valueKey)).text;

  PatrolFinder _linksTabItem(String url) =>
      $(ChatDetailsLinkItem).containing(find.text(url));

  PatrolFinder linksTabItemTitle(String url, String title) =>
      _linksTabItem(url).$(find.text(title));
}
