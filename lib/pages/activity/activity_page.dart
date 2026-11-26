import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/domain/activity/usecases/mark_room_read_use_case.provider.dart';
import 'package:twake_chat/domain/activity/usecases/watch_activity_use_case.provider.dart';
import 'package:twake_chat/domain/activity/usecases/watch_unread_mention_count_use_case.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/activity/activity_day_groups.dart';
import 'package:twake_chat/pages/activity/activity_filter.dart';
import 'package:twake_chat/pages/activity/activity_open_item.dart';
import 'package:twake_chat/pages/activity/activity_row.dart';
import 'package:twake_chat/pages/activity/activity_search.dart';
import 'package:twake_chat/pages/activity/activity_view_controller.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_appbar_style.dart';
import 'package:twake_chat/widgets/avatar/settings_avatar_button.dart';

/// THR-M-12: the tab that gathers what happened in the rooms of the user.
class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({
    super.key,
    this.bottomNavigationBar,
    this.onOpenSettings,
  });

  final Widget? bottomNavigationBar;

  /// The avatar of the phone app bar opens Settings.
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(activityViewControllerProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _markRead(String roomId) =>
      _markReadWith(ref.read(markRoomReadUseCaseProvider).execute, roomId);

  Future<void> _markReadWith(
    Future<void> Function(String roomId) markRead,
    String roomId,
  ) async {
    try {
      await markRead(roomId);
    } on Exception {
      // Logged by the use case. The room stays in the list: the button can be pressed again.
    }
  }

  /// At most 3 receipts at a time: a long list must not hit the rate limit.
  Future<void> _markAllRead(List<String> roomIds) {
    // Read once, before the workers: leaving the page mid-run must not touch ref.
    final markRead = ref.read(markRoomReadUseCaseProvider).execute;
    final pending = roomIds.iterator;
    Future<void> markNext() async {
      while (pending.moveNext()) {
        await _markReadWith(markRead, pending.current);
      }
    }

    return Future.wait(
      List.generate(min(3, roomIds.length), (_) => markNext()),
    );
  }

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
    // The search is reset with the account, not by typing.
    ref.listen(activityViewControllerProvider, (_, next) {
      if (next.query != _search.text) _search.text = next.query;
    });
    final count = ref.watch(unreadMentionCountProvider).value ?? 0;
    final rooms = ref.watch(activityItemsProvider).value ?? const [];
    final isMobile = ContactsAppbarStyle.responsiveUtils.isMobile(context);
    final mentions = ref.watch(activityMentionsProvider);
    final reactions = ref.watch(activityReactionsProvider).value ?? const [];
    final items = [...rooms, ...?mentions.value, ...reactions];
    final shown = searchActivity(
      items.where((item) => view.filter.includes(item.kind)),
      view.query,
    );
    final unreadRoomIds = [
      for (final item in rooms)
        if (item.kind == ActivityKind.unreadRoom) item.roomId,
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: widget.bottomNavigationBar,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            !ContactsAppbarStyle.responsiveUtils.isDesktop(context) &&
                widget.onOpenSettings != null
            ? Center(child: SettingsAvatarButton(onTap: widget.onOpenSettings))
            : null,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: ref
                  .read(activityViewControllerProvider.notifier)
                  .search,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
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
