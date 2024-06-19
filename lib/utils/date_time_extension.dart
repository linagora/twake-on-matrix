import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:intl/intl.dart';

const _fullMonthWithDayPattern = "MMMM d";
const _fullMonthWithDayAndYearPattern = "MMMM d, y";
const _dayMonthYearSlashSeparatedPattern = "dd/MM/yy";
const _shortMonthWithDayPattern = "MMM d";

/// Provides extra functionality for formatting the time.
extension DateTimeExtension on DateTime {
  bool operator <(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  bool operator >(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  bool operator >=(DateTime other) {
    return millisecondsSinceEpoch >= other.millisecondsSinceEpoch;
  }

  bool operator <=(DateTime other) {
    return millisecondsSinceEpoch <= other.millisecondsSinceEpoch;
  }

  /// Two message events can belong to the same environment. That means that they
  /// don't need to display the time they were sent because they are close
  /// enaugh.
  static const minutesBetweenEnvironments = 5;

  /// Checks if two DateTimes are close enough to belong to the same
  /// environment.
  bool sameEnvironment(DateTime prevTime) {
    return DateUtils.isSameDay(this, prevTime);
  }

  /// Returns a simple time String.
  /// TODO: Add localization
  String localizedTimeOfDay(BuildContext context) {
    return '${_z(hour)}:${_z(minute)}';
  }

  /// Returns [localizedTimeOfDay()] if the ChatTime is today, the name of the week
  /// day if the ChatTime is this week and a date string else.
  String localizedTimeShort(BuildContext context, {DateTime? currentTime}) {
    currentTime ??= DateTime.now();

    final sameYear = currentTime.year == year;

    final sameDay =
        sameYear && currentTime.month == month && currentTime.day == day;

    final sameWeek = isInCurrentWeek(currentTime: currentTime);

    if (sameDay) {
      return localizedTimeOfDay(context);
    } else if (sameWeek) {
      switch (weekday) {
        case 1:
          return L10n.of(context)!.monday;
        case 2:
          return L10n.of(context)!.tuesday;
        case 3:
          return L10n.of(context)!.wednesday;
        case 4:
          return L10n.of(context)!.thursday;
        case 5:
          return L10n.of(context)!.friday;
        case 6:
          return L10n.of(context)!.saturday;
        case 7:
          return L10n.of(context)!.sunday;
      }
    } else if (sameYear) {
      return _formatDateWithLocale(context, _shortMonthWithDayPattern);
    } else {
      return _formatDateWithLocale(context, _dayMonthYearSlashSeparatedPattern);
    }
    return L10n.of(context)!.dateWithYear(
      year.toString(),
      month.toString().padLeft(2, '0'),
      day.toString().padLeft(2, '0'),
    );
  }

  bool isInCurrentWeek({DateTime? currentTime}) {
    currentTime ??= DateTime.now();

    final currentWeekStart =
        currentTime.subtract(Duration(days: currentTime.weekday - 1));

    final weekStart = subtract(Duration(days: weekday - 1));

    return currentWeekStart.year == weekStart.year &&
        currentWeekStart.month == weekStart.month &&
        currentWeekStart.day == weekStart.day;
  }

  /// If the DateTime is today, this returns [localizedTimeOfDay()], if not it also
  /// shows the date.
  /// TODO: Add localization
  String localizedTime(BuildContext context) {
    final now = DateTime.now();

    final sameYear = now.year == year;

    final sameDay = sameYear && now.month == month && now.day == day;

    if (sameDay) return localizedTimeOfDay(context);
    return L10n.of(context)!.dateAndTimeOfDay(
      localizedTimeShort(context),
      localizedTimeOfDay(context),
    );
  }

  static String _z(int i) => i < 10 ? '0${i.toString()}' : i.toString();

  bool isToday({DateTime? currentTime}) {
    currentTime ??= DateTime.now();
    return DateUtils.isSameDay(this, currentTime);
  }

  bool isYesterday({DateTime? currentTime}) {
    currentTime ??= DateTime.now();
    final yesterday = currentTime.subtract(const Duration(days: 1));
    return DateUtils.isSameDay(this, yesterday);
  }

  bool isSameYear({DateTime? currentTime}) {
    currentTime ??= DateTime.now();
    return currentTime.year == year;
  }

  String relativeTime(BuildContext context, {DateTime? currentTime}) {
    if (isToday(currentTime: currentTime)) {
      return L10n.of(context)!.today;
    } else if (isYesterday(currentTime: currentTime)) {
      return L10n.of(context)!.yesterday;
    } else if (isSameYear(currentTime: currentTime)) {
      return _formatDateWithLocale(context, _fullMonthWithDayPattern);
    } else {
      return _formatDateWithLocale(context, _fullMonthWithDayAndYearPattern);
    }
  }

  String getFormattedCurrentDateTime() {
    return millisecondsSinceEpoch.toString();
  }

  bool isLessThanOneMinuteAgo({DateTime? other}) {
    other ??= DateTime.now();
    return other.difference(this) < const Duration(minutes: 1);
  }

  bool isLessThanOneHourAgo({DateTime? other}) {
    other ??= DateTime.now();
    return other.difference(this) < const Duration(hours: 1);
  }

  bool isLessThanADayAgo({DateTime? other}) {
    other ??= DateTime.now();
    return other.difference(this) < const Duration(hours: 24);
  }

  bool isLessThan30DaysAgo({DateTime? other}) {
    other ??= DateTime.now();
    return other.difference(this) < const Duration(days: 30);
  }

  String _formatDateWithLocale(BuildContext context, String pattern) {
    final currentLanguageCode =
        LocalizationService.currentLocale.value.languageCode;

    final formattedDate = DateFormat(
      pattern,
      currentLanguageCode,
    ).format(this);

    switch (pattern) {
      case _fullMonthWithDayPattern:
      case _fullMonthWithDayAndYearPattern:
      case _shortMonthWithDayPattern:
        return formattedDate[0].toUpperCase() + formattedDate.substring(1);
      default:
        return formattedDate;
    }
  }
}
