import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_actions.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/settings_folders_style.dart';
import 'package:twake_chat/presentation/extensions/folder_extension.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

/// The folders of the user: reorder, edit, delete, add one.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final folders = ref.watch(roomListFoldersProvider);
    return Scaffold(
      appBar: TwakeAppBar(
        title: l10n.foldersTitle,
        context: context,
        withDivider: true,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: SettingsFoldersStyle.backPadding,
          icon: Icons.arrow_back_ios,
          tooltip: l10n.back,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      // One scrollable, so a long drag scrolls the list by itself.
      body: ReorderableListView(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: SettingsFoldersStyle.introPadding,
              child: Text(
                l10n.foldersIntro,
                style: SettingsFoldersStyle.helpText,
              ),
            ),
            LinagoraSettingItem(
              key: const ValueKey('folder_new'),
              leadingIcon: Icons.create_new_folder_outlined,
              iconColor: LinagoraSysColors.material().primary,
              titleColor: LinagoraSysColors.material().primary,
              title: l10n.folderNew,
              padding: SettingsFoldersStyle.rowPadding,
              trailing: const SizedBox.shrink(),
              onTap: () => const FolderEditRoute().push<void>(context),
            ),
            if (folders.isNotEmpty)
              LinagoraSectionHeader(label: l10n.foldersYours.toUpperCase()),
          ],
        ),
        footer: const _RecommendedFolders(),
        onReorderItem: (from, to) => runFolderAction(
          context,
          () => ref.read(foldersControllerProvider.notifier).reorder(from, to),
        ),
        // A long press reorders everywhere: the desktop handle would cover Delete.
        buildDefaultDragHandles: false,
        children: [
          for (final (index, folder) in folders.indexed)
            ReorderableDelayedDragStartListener(
              key: ValueKey(RoomListFilter.of(folder)),
              index: index,
              child: _FolderRow(folder: folder),
            ),
        ],
      ),
    );
  }
}

/// The built-ins the user deleted, to bring back.
class _RecommendedFolders extends ConsumerWidget {
  const _RecommendedFolders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final shown = ref
        .watch(roomListFoldersProvider)
        .whereType<BuiltinFolderEntry>()
        .map((folder) => folder.kind);
    final hidden = BuiltinFolder.values.where((kind) => !shown.contains(kind));
    if (hidden.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinagoraSectionHeader(label: l10n.foldersRecommended.toUpperCase()),
        for (final kind in hidden)
          LinagoraSettingItem(
            padding: SettingsFoldersStyle.rowPadding,
            title: kind.label(l10n),
            subtitle: kind.rule(l10n),
            trailing: LinagoraButton(
              variant: LinagoraButtonVariant.text,
              size: LinagoraButtonSize.xs,
              label: l10n.add,
              onPressed: () => runFolderAction(
                context,
                () => ref
                    .read(foldersControllerProvider.notifier)
                    .addBuiltin(kind),
              ),
            ),
          ),
      ],
    );
  }
}

/// A folder, its badge and rule centred on its delete button.
class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final subtitle = switch (folder) {
      BuiltinFolderEntry(:final kind) => kind.rule(l10n),
      UserFolder() => null,
    };
    return InkWell(
      onTap: () => folder.pushEdit(context),
      child: Padding(
        padding: SettingsFoldersStyle.folderRowPadding,
        child: Row(
          spacing: SettingsFoldersStyle.rowGap,
          children: [
            FolderBadge(folder: folder),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folder.label(l10n),
                    style: LinagoraTextStyle.material().bodyMedium2.copyWith(
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: LinagoraTextStyle.material().bodyMedium.copyWith(
                        color: LinagoraRefColors.material().tertiary[30],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            LinagoraIconButton(
              key: const ValueKey('folder_delete'),
              icon: Icons.delete_outline,
              iconSize: SettingsFoldersStyle.deleteIconSize,
              color: colors.tertiary,
              padding: SettingsFoldersStyle.deletePadding,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              tooltip: l10n.folderDelete,
              onPressed: () => confirmAndRemoveFolder(context, ref, folder),
            ),
          ],
        ),
      ),
    );
  }
}

/// The emoji of the folder on its colour, or on grey without one.
class FolderBadge extends StatelessWidget {
  const FolderBadge({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final color = folder.color;
    final tint = color == null
        ? LinagoraSysColors.material().tertiary
        : Color(color.argb);
    return Container(
      width: SettingsFoldersStyle.badgeSize,
      height: SettingsFoldersStyle.badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: SettingsFoldersStyle.tintAlpha),
      ),
      child: Text(
        folder.emoji ?? SettingsFoldersStyle.defaultFolderEmoji,
        textAlign: TextAlign.center,
        // A line box as tall as the glyph, so the emoji centres on the badge.
        style: LinagoraTextStyle.material().titleLarge.copyWith(height: 1),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}
