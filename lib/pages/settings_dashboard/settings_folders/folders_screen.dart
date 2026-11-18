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
        children: [
          for (final folder in folders)
            LinagoraSettingItem(
              key: ValueKey(RoomListFilter.of(folder)),
              leading: _FolderLeading(folder: folder),
              padding: SettingsFoldersStyle.rowPadding,
              title: folder.label(l10n),
              subtitle: switch (folder) {
                BuiltinFolderEntry(:final kind) => kind.rule(l10n),
                UserFolder() => null,
              },
              onTap: () => folder.pushEdit(context),
              trailing: LinagoraIconButton(
                icon: Icons.delete_outline,
                tooltip: l10n.folderDelete,
                onPressed: () => confirmAndRemoveFolder(context, ref, folder),
              ),
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

/// The emoji of the folder over its colour, or a plain folder.
class _FolderLeading extends StatelessWidget {
  const _FolderLeading({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final color = folder.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color == null
            ? null
            : Color(
                color.argb,
              ).withValues(alpha: SettingsFoldersStyle.tintAlpha),
      ),
      child: Center(
        child: Text(
          folder.emoji ?? SettingsFoldersStyle.defaultFolderEmoji,
          style: LinagoraTextStyle.material().titleMedium,
        ),
      ),
    );
  }
}
