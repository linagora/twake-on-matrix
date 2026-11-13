import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_menu_controller.dart';

enum _ThreadMenuAction {
  follow,
  unfollow,
  mute,
  unmute,
  resolve,
  reopen;

  String label(L10n l10n) => switch (this) {
    follow => l10n.threadFollow,
    unfollow => l10n.threadUnfollow,
    mute => l10n.threadMute,
    unmute => l10n.threadUnmute,
    resolve => l10n.threadMarkResolved,
    reopen => l10n.threadReopen,
  };

  Future<bool> run(ThreadMenuController menu) => switch (this) {
    follow => menu.follow(),
    unfollow => menu.unfollow(),
    mute => menu.mute(),
    unmute => menu.unmute(),
    resolve => menu.resolve(),
    reopen => menu.reopen(),
  };
}

List<_ThreadMenuAction> _actionsFor(ThreadStatus status) => [
  ..._followActions(status.follow),
  ?_resolveAction(status),
];

List<_ThreadMenuAction> _followActions(ThreadFollow follow) {
  if (!follow.isFollowing) return const [_ThreadMenuAction.follow];
  return [
    _ThreadMenuAction.unfollow,
    follow.isMuted ? _ThreadMenuAction.unmute : _ThreadMenuAction.mute,
  ];
}

/// Only who may set the resolved state of the room is offered it.
_ThreadMenuAction? _resolveAction(ThreadStatus status) {
  if (!status.canResolve) return null;
  return status.isResolved
      ? _ThreadMenuAction.reopen
      : _ThreadMenuAction.resolve;
}

/// The « ⋮ » menu of the thread header: follow, mute and resolved state.
/// Shown but disabled until the account has answered, and while a change is
/// being saved.
class ThreadMenuButton extends ConsumerWidget {
  const ThreadMenuButton({super.key, required this.thread});

  final ThreadRef thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = threadMenuControllerProvider(thread);
    final status = ref.watch(provider.select((state) => state.status));
    final isSaving = ref.watch(provider.select((state) => state.isSaving));
    final hasFailed = ref.watch(provider.select((state) => state.hasFailed));
    final l10n = L10n.of(context)!;
    if (status == null && hasFailed) return _unreadableMenu(context, l10n);
    return PopupMenuButton<_ThreadMenuAction>(
      tooltip: l10n.more,
      enabled: status != null && !isSaving,
      itemBuilder: (_) => [
        for (final action in _actionsFor(status!))
          PopupMenuItem(value: action, child: Text(action.label(l10n))),
      ],
      onSelected: (action) async {
        final messenger = ScaffoldMessenger.of(context);
        final isSaved = await action.run(ref.read(provider.notifier));
        if (!isSaved) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.threadChangeFailed)),
          );
        }
      },
    );
  }

  /// Else the menu stays disabled without a word.
  Widget _unreadableMenu(BuildContext context, L10n l10n) => IconButton(
    tooltip: l10n.more,
    icon: const Icon(Icons.more_vert),
    onPressed: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.oopsSomethingWentWrong))),
  );
}
