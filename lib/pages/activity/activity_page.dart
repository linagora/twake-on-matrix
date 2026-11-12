import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/activity/activity_day_groups.dart';
import 'package:twake_chat/pages/activity/activity_filter.dart';
import 'package:twake_chat/pages/activity/activity_open_item.dart';
import 'package:twake_chat/pages/activity/activity_row.dart';
import 'package:twake_chat/pages/activity/activity_view_controller.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_appbar_style.dart';

/// THR-M-12: the tab that gathers what happened in the rooms of the user.
class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key, this.bottomNavigationBar});

  final Widget? bottomNavigationBar;

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  Future<void> _markRead(String roomId) async {
    try {
      await ref.read(activityRepositoryProvider).markRoomRead(roomId);
    } catch (e) {
      // The room stays in the list: the button can be pressed again.
      debugPrint('Unable to mark the room as read: $e');
    }
  }

  Future<void> _markAllRead(List<String> roomIds) =>
      Future.wait(roomIds.map(_markRead));

  /// The mentions come from the server: a progress while they load, a way to
  /// ask again when they cannot be read.
  Widget _mentionsList(
    BuildContext context,
    AsyncValue<List<ActivityItem>> mentions,
    Iterable<ActivityItem> shown,
    ActivityFilter filter,
  ) => switch (mentions) {
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
    AsyncError() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(L10n.of(context)!.activityMentionsLoadFailed),
          TextButton(
            onPressed: () => ref.invalidate(activityMentionsProvider),
            child: Text(L10n.of(context)!.activityTryAgain),
          ),
        ],
      ),
    ),
    _ => _list(context, shown, filter),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final view = ref.watch(activityViewControllerProvider);
    final count = ref.watch(unreadMentionCountProvider).value ?? 0;
    final rooms = ref.watch(activityItemsProvider).value ?? const [];
    final isMobile = ContactsAppbarStyle.responsiveUtils.isMobile(context);
    final mentions = ref.watch(activityMentionsProvider);
    final items = [...rooms, ...?mentions.value];
    final shown = items.where((item) => view.filter.includes(item.kind));
    final unreadRoomIds = [
      for (final item in rooms)
        if (item.kind == ActivityKind.unreadRoom) item.roomId,
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: widget.bottomNavigationBar,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // As the title of Chats: centred on a phone, 16 px in on a wide screen.
        centerTitle: isMobile,
        title: Padding(
          padding: ContactsAppbarStyle.titlePadding(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(l10n.activity, overflow: TextOverflow.ellipsis),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                _CountBadge(count: count),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: unreadRoomIds.isEmpty
                ? null
                : () => _markAllRead(unreadRoomIds),
            child: Text(l10n.activityMarkAllRead),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            selected: view.filter,
            onSelected: ref
                .read(activityViewControllerProvider.notifier)
                .selectFilter,
          ),
          Expanded(
            child: view.filter == ActivityFilter.mentions
                ? _mentionsList(context, mentions, shown, view.filter)
                : _list(context, shown, view.filter),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    Iterable<ActivityItem> shown,
    ActivityFilter filter,
  ) {
    final entries = groupByDay(shown);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          filter == ActivityFilter.replies
              ? L10n.of(context)!.activityNoThreadFollowed
              : L10n.of(context)!.activityNothingToShow,
          style: LinagoraTextStyle.material().bodyMedium.copyWith(
            color: LinagoraSysColors.material().secondary,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        ActivityDayHeader(:final day) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            dayLabel(context, day),
            style: LinagoraTextStyle.material().labelLarge.copyWith(
              color: LinagoraSysColors.material().secondary,
            ),
          ),
        ),
        ActivityItemEntry(:final item) => ActivityRow(
          item: item,
          onTap: () => openActivityItem(context, item),
          onMarkRead: () => _markRead(item.roomId),
        ),
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: scheme.onError),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelected});

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    // The four filters share the width, whatever the size of the text.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final filter in ActivityFilter.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  labelPadding: EdgeInsets.zero,
                  label: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(filter.label(l10n)),
                    ),
                  ),
                  selected: filter == selected,
                  onSelected: (_) => onSelected(filter),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
