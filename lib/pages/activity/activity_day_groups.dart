import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// What the list shows: a day header, or an item.
sealed class ActivityEntry {
  const ActivityEntry();
}

class ActivityDayHeader extends ActivityEntry {
  const ActivityDayHeader(this.day);

  final DateTime day;
}

class ActivityItemEntry extends ActivityEntry {
  const ActivityItemEntry(this.item);

  final ActivityItem item;
}

/// [items], newest first, each day under its header.
List<ActivityEntry> groupByDay(Iterable<ActivityItem> items) {
  final sorted = items.toList()..sort((a, b) => b.time.compareTo(a.time));
  final entries = <ActivityEntry>[];
  DateTime? current;
  for (final item in sorted) {
    final time = item.time.toLocal();
    final day = DateTime(time.year, time.month, time.day);
    if (day != current) {
      current = day;
      entries.add(ActivityDayHeader(day));
    }
    entries.add(ActivityItemEntry(item));
  }
  return entries;
}

/// « Today », « Yesterday », then the date.
String dayLabel(BuildContext context, DateTime day) {
  final l10n = L10n.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return l10n.today;
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return l10n.yesterday;
  }
  return DateFormat.yMMMMd(
    Localizations.localeOf(context).toString(),
  ).format(day);
}
