import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

/// The items whose author, room, thread or quoted message hold every word of
/// [query], whatever the case and the accents.
List<ActivityItem> searchActivity(Iterable<ActivityItem> items, String query) {
  final matchers = [
    for (final word in query.split(RegExp(r'\s+')))
      if (word.isNotEmpty)
        const SearchEngine().buildMatcher(
          word,
          options: const SearchOptions(diacriticSensitive: false),
        ),
  ];
  if (matchers.isEmpty) return items.toList();
  return items.where((item) {
    final fields = [
      item.authorName,
      item.roomName,
      item.threadTitle,
      item.quote,
    ].whereType<String>();
    return matchers.every((matcher) => fields.any(matcher.matches));
  }).toList();
}
