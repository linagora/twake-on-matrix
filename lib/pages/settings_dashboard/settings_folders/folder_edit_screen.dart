import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart' as emoji_mart;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    hide WidgetBuilder;
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_actions.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/settings_folders_style.dart';
import 'package:twake_chat/presentation/extensions/folder_extension.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/utils/adaptive_bottom_sheet.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:twake_chat/providers/emoji_data_provider.dart';

/// Back where the form was opened from, or the folders after a reload.
void _leaveForm(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    const FoldersRoute().go(context);
  }
}

TwakeAppBar _formAppBar(BuildContext context, String title) => TwakeAppBar(
  title: title,
  context: context,
  withDivider: true,
  enableLeftTitle: true,
  leading: TwakeIconButton(
    paddingAll: SettingsFoldersStyle.backPadding,
    icon: Icons.arrow_back_ios,
    tooltip: L10n.of(context)!.back,
    onTap: () => _leaveForm(context),
  ),
);

/// Waits for the folders of the account: a reload lands here before they are
/// read, and the form takes its first values once. They may never come: the bar
/// stays a way out.
class _WaitForFolders extends ConsumerWidget {
  const _WaitForFolders({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoaded = ref.watch(
      foldersControllerProvider.select((state) => state.isLoaded),
    );
    return isLoaded
        ? builder(context)
        : Scaffold(
            appBar: _formAppBar(context, L10n.of(context)!.chatFolders),
            body: const Center(child: CircularProgressIndicator()),
          );
  }
}

/// Edits the looks of a built-in; its rule stays.
class BuiltinFolderEditScreen extends StatelessWidget {
  const BuiltinFolderEditScreen({super.key, required this.kind});

  final BuiltinFolder kind;

  @override
  Widget build(BuildContext context) =>
      _WaitForFolders(builder: (_) => _BuiltinFolderForm(kind: kind));
}

/// Makes a folder, or edits the one named [name].
class FolderEditScreen extends StatelessWidget {
  const FolderEditScreen({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) =>
      _WaitForFolders(builder: (_) => _UserFolderForm(name: name));
}

class _BuiltinFolderForm extends ConsumerStatefulWidget {
  const _BuiltinFolderForm({required this.kind});

  final BuiltinFolder kind;

  @override
  ConsumerState<_BuiltinFolderForm> createState() => _BuiltinFolderFormState();
}

class _BuiltinFolderFormState extends ConsumerState<_BuiltinFolderForm> {
  late final BuiltinFolderEntry _current = ref
      .read(roomListFoldersProvider)
      .whereType<BuiltinFolderEntry>()
      .firstWhere(
        (folder) => folder.kind == widget.kind,
        orElse: () => BuiltinFolderEntry(widget.kind),
      );
  late final _name = TextEditingController(text: _current.name);
  late String? _emoji = _current.emoji;
  late FolderColor? _color = _current.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = L10n.of(context)!;
    final typed = _name.text.trim();
    final isSaved = await runFolderAction(
      context,
      () => ref
          .read(foldersControllerProvider.notifier)
          .saveBuiltin(
            // Its own name is not kept: it follows the language.
            edited: _current.copyWith(
              name: typed.toLowerCase() == widget.kind.label(l10n).toLowerCase()
                  ? ''
                  : typed,
              emoji: _emoji,
              color: _color,
            ),
            reservedNames: builtinFolderLabels(l10n)
              ..remove(widget.kind.label(l10n)),
          ),
    );
    if (isSaved && mounted) _leaveForm(context);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: L10n.of(context)!.folderEdit,
      onSave: _save,
      children: [
        _LooksFields(
          name: _name,
          emoji: _emoji,
          onEmojiChanged: (emoji) => setState(() => _emoji = emoji),
          nameHint: widget.kind.label(L10n.of(context)!),
          color: _color,
          onColorChanged: (color) => setState(() => _color = color),
        ),
      ],
    );
  }
}

class _UserFolderForm extends ConsumerStatefulWidget {
  const _UserFolderForm({required this.name});

  final String? name;

  @override
  ConsumerState<_UserFolderForm> createState() => _UserFolderFormState();
}

class _UserFolderFormState extends ConsumerState<_UserFolderForm> {
  late final UserFolder? _current = ref
      .read(roomListFoldersProvider)
      .whereType<UserFolder>()
      .firstWhereOrNull((folder) => folder.name == widget.name);
  late final _name = TextEditingController(text: _current?.name ?? '');
  late String? _emoji = _current?.emoji;
  late FolderColor? _color = _current?.color;
  late List<FolderChatType> _include = [...?_current?.include];

  /// The chats when the form opened: what comes later is not the user's
  /// choice.
  late final List<RoomListEntry> _chats = ref
      .read(roomListEntriesProvider)
      .where((entry) => !entry.isSpace)
      .toList();

  /// Every chat's name, to tell the parent space of a chat apart.
  late final Map<String, String> _names = {
    for (final entry in ref.read(roomListEntriesProvider)) entry.id: entry.name,
  };
  late final Set<String> _picked = {
    for (final chat in _chats)
      if (_current case final current? when isInFolder(chat, current)) chat.id,
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggleType(FolderChatType type, bool isOn) {
    setState(() {
      _include = FolderChatType.values
          .where((each) => each == type ? isOn : _include.contains(each))
          .toList();
      // The chats of that kind follow it, as the folder will.
      for (final entry in _chats) {
        if (folderChatTypeOf(entry) != type) continue;
        isOn ? _picked.add(entry.id) : _picked.remove(entry.id);
      }
    });
  }

  Future<void> _save() async {
    final l10n = L10n.of(context)!;
    final isSaved = await runFolderAction(
      context,
      () => ref
          .read(foldersControllerProvider.notifier)
          .saveUserFolder(
            edited: UserFolder(
              _name.text,
              emoji: _emoji,
              color: _color,
              include: _include,
            ),
            previous: _current,
            picked: _picked,
            chats: _chats,
            reservedNames: builtinFolderLabels(l10n),
          ),
    );
    if (isSaved && mounted) _leaveForm(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return _FormScaffold(
      title: _current == null ? l10n.folderNew : l10n.folderEdit,
      onSave: _save,
      rowCount: _chats.length,
      rowBuilder: (context, index) {
        final chat = _chats[index];
        return _ChatRow(
          chat: chat,
          parentNames: [for (final id in chat.parentSpaceIds) ?_names[id]],
          isPicked: _picked.contains(chat.id),
          onChanged: (isOn) => setState(() {
            isOn ? _picked.add(chat.id) : _picked.remove(chat.id);
          }),
        );
      },
      children: [
        _LooksFields(
          name: _name,
          emoji: _emoji,
          onEmojiChanged: (emoji) => setState(() => _emoji = emoji),
          autofocus: _current == null,
          color: _color,
          onColorChanged: (color) => setState(() => _color = color),
        ),
        _TypePicker(include: _include, onChanged: _toggleType),
        const _ChatPickerHeader(),
      ],
    );
  }
}

class _FormScaffold extends StatefulWidget {
  const _FormScaffold({
    required this.title,
    required this.onSave,
    required this.children,
    this.rowCount = 0,
    this.rowBuilder,
  });

  final String title;
  final Future<void> Function() onSave;
  final List<Widget> children;

  /// Rows after [children], built when they scroll into view.
  final int rowCount;
  final IndexedWidgetBuilder? rowBuilder;

  @override
  State<_FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends State<_FormScaffold> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave();
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _formAppBar(context, widget.title),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: SettingsFoldersStyle.padding.copyWith(bottom: 0),
            sliver: SliverList.list(children: widget.children),
          ),
          if (widget.rowBuilder case final rowBuilder?)
            SliverList.builder(
              itemCount: widget.rowCount,
              itemBuilder: rowBuilder,
            ),
          SliverPadding(
            padding: SettingsFoldersStyle.padding,
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LinagoraButton(
                  key: const ValueKey('folder_save'),
                  label: L10n.of(context)!.save,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LooksFields extends StatelessWidget {
  const _LooksFields({
    required this.name,
    required this.emoji,
    required this.onEmojiChanged,
    required this.color,
    required this.onColorChanged,
    this.nameHint,
    this.autofocus = false,
  });

  final TextEditingController name;
  final String? emoji;
  final ValueChanged<String?> onEmojiChanged;
  final FolderColor? color;
  final ValueChanged<FolderColor?> onColorChanged;
  final String? nameHint;
  final bool autofocus;

  // The design system's field has no length limit of its own.
  void _capName(String value) {
    final current = name.value;
    final excess = value.characters.length - SettingsFoldersStyle.maxNameLength;
    if (excess <= 0 || current.composing.isValid) return;
    // What was just typed goes, not the end of the name.
    final caret = current.selection.isValid
        ? current.selection.end
        : value.length;
    final typed = value.substring(0, caret).characters;
    final kept = typed.take(max(typed.length - excess, 0)).string;
    name.value = TextEditingValue(
      text: (kept + value.substring(caret)).characters
          .take(SettingsFoldersStyle.maxNameLength)
          .string,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SettingsFoldersStyle.smallGap,
      children: [
        Row(
          spacing: SettingsFoldersStyle.smallGap,
          children: [
            _EmojiButton(emoji: emoji, onChanged: onEmojiChanged),
            Expanded(
              child: LinagoraTextField(
                key: const ValueKey('folder_name'),
                controller: name,
                autofocus: autofocus,
                label: l10n.folderName,
                hintText: nameHint,
                variant: LinagoraTextFieldVariant.outline,
                onChanged: _capName,
              ),
            ),
          ],
        ),
        Text(l10n.folderColor, style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: SettingsFoldersStyle.chipGap,
          children: [
            LinagoraFilterChip(
              label: l10n.folderNoColor,
              selected: color == null,
              onSelected: (_) => onColorChanged(null),
            ),
            for (final (index, each) in SettingsFoldersStyle.palette.indexed)
              Tooltip(
                message: '${l10n.folderColor} ${index + 1}',
                child: ChoiceChip(
                  label: const SizedBox.square(
                    dimension: SettingsFoldersStyle.colorSwatchSize,
                  ),
                  backgroundColor: Color(each.argb),
                  selected: color == each,
                  onSelected: (_) => onColorChanged(each),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.include, required this.onChanged});

  final List<FolderChatType> include;
  final void Function(FolderChatType type, bool isOn) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SettingsFoldersStyle.gap),
        Text(
          l10n.folderIncluded,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(l10n.folderIncludedHelp),
        for (final type in FolderChatType.values)
          LinagoraSettingItem.selectable(
            key: ValueKey('folder_type_${type.name}'),
            control: LinagoraSettingItemControl.checkbox,
            title: switch (type) {
              FolderChatType.direct => l10n.folderTypeDirect,
              FolderChatType.group => l10n.folderTypeGroup,
              FolderChatType.broadcast => l10n.folderTypeBroadcast,
              FolderChatType.bot => l10n.folderTypeBot,
            },
            value: include.contains(type),
            onChanged: (isOn) => onChanged(type, isOn),
          ),
      ],
    );
  }
}

class _ChatPickerHeader extends StatelessWidget {
  const _ChatPickerHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: SettingsFoldersStyle.gap),
    child: Text(
      L10n.of(context)!.chats,
      style: Theme.of(context).textTheme.titleSmall,
    ),
  );
}

/// A chat to tick: its avatar, and its space so that equal names differ.
class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.chat,
    required this.parentNames,
    required this.isPicked,
    required this.onChanged,
  });

  final RoomListEntry chat;
  final List<String> parentNames;
  final bool isPicked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return LinagoraSettingItem.selectable(
      key: ValueKey('folder_chat_${chat.id}'),
      control: LinagoraSettingItemControl.checkbox,
      leading: Avatar(
        mxContent: chat.avatar,
        name: chat.name,
        size: SettingsFoldersStyle.chatAvatarSize,
      ),
      title: chat.name,
      subtitle: parentNames.isEmpty ? null : parentNames.join(', '),
      value: isPicked,
      onChanged: onChanged,
    );
  }
}

/// The emoji of the folder, from the picker of the chat.
class _EmojiButton extends ConsumerWidget {
  const _EmojiButton({required this.emoji, required this.onChanged});

  final String? emoji;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final textTheme = Theme.of(context).textTheme;
    final picked = await showAdaptiveBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: SettingsFoldersStyle.emojiPickerHeight,
        child: emoji_mart.EmojiPicker(
          emojiData: ref.read(emojiDataProvider).requireValue,
          configuration: emoji_mart.EmojiPickerConfiguration(
            emojiStyle: textTheme.headlineLarge!,
          ),
          onEmojiSelected: (emojiId, emoji) =>
              Navigator.of(sheetContext).pop(emoji),
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final emoji = this.emoji;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: l10n.folderEmoji,
          child: LinagoraButton(
            key: const ValueKey('folder_emoji'),
            label: emoji ?? SettingsFoldersStyle.defaultEmoji,
            variant: LinagoraButtonVariant.outlined,
            onPressed: () => _pick(context, ref),
          ),
        ),
        if (emoji != null)
          LinagoraIconButton(
            key: const ValueKey('folder_emoji_clear'),
            icon: Icons.close,
            tooltip: l10n.clear,
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}
