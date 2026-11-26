import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/pages/scribe/scribe_controller.dart';
import 'package:twake_chat/pages/scribe/scribe_failure_message.dart';
import 'package:twake_chat/pages/scribe/scribe_menu.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

class ScribeButton extends ConsumerStatefulWidget {
  const ScribeButton({
    super.key,
    required this.roomId,
    required this.draft,
    required this.onRewritten,
  });

  final String roomId;

  final TextEditingController draft;

  final ValueChanged<String> onRewritten;

  @override
  ConsumerState<ScribeButton> createState() => _ScribeButtonState();
}

class _ScribeButtonState extends ConsumerState<ScribeButton> {
  static const _failureMessage = ScribeFailureMessage();
  static const double _progressSize = 20;

  static const double _iconGap = LinagoraSpacing.base * 1.5;
  static const double _buttonWidth =
      ChatInputRowStyle.chatInputRowMoreBtnSize + _iconGap;
  static const double _menuWidth = 200;

  final _menuController = MenuController();
  ScribeMenu _menu = ScribeMenu.root;

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(
      driveConfigProvider.select((config) => config.isEnabled),
    );
    if (!isConfigured) return const SizedBox.shrink();
    final room = ref.watch(scribeRoomProvider(widget.roomId)).value;
    if (room == null || !room.offersScribe) {
      return const SizedBox.shrink();
    }
    final isRewriting = ref.watch(scribeControllerProvider(widget.roomId));
    final host = ref.watch(
      driveSessionProvider.select((session) => session?.platformUrl.host),
    );
    final l10n = L10n.of(context)!;
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        minimumSize: WidgetStatePropertyAll(Size(_menuWidth, 0)),
      ),
      menuChildren: _menuChildren(l10n, room, host),
      builder: (context, controller, _) => SizedBox(
        width: _buttonWidth,
        height: ChatInputRowStyle.chatInputRowHeight,
        child: isRewriting
            ? const Padding(
                padding: EdgeInsetsDirectional.only(end: _iconGap),
                child: Center(
                  child: SizedBox.square(
                    dimension: _progressSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                tooltip: l10n.scribe,
                padding: const EdgeInsetsDirectional.only(end: _iconGap),
                constraints: const BoxConstraints(),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: ChatInputRowStyle.chatInputRowMoreBtnSize,
                icon: SvgPicture.asset(
                  Assets.images.icScribe.path,
                  width: ChatInputRowStyle.chatInputRowMoreBtnSize,
                  height: ChatInputRowStyle.chatInputRowMoreBtnSize,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _open,
              ),
      ),
    );
  }

  void _open() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _menu = ScribeMenu.root);
    _menuController.open();
  }

  List<Widget> _menuChildren(L10n l10n, ScribeRoom room, String? host) {
    final isBlank = widget.draft.text.trim().isEmpty;
    return [
      if (room.isEncrypted) _encryptionNotice(l10n, host),
      if (_menu != ScribeMenu.root)
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _menu = ScribeMenu.root),
          child: Text(_titleOf(l10n, _menu)),
        ),
      for (final entry in _menu.entries)
        switch (entry) {
          ScribeSubmenuEntry(:final menu) => MenuItemButton(
            closeOnActivate: false,
            leadingIcon: Icon(_iconOfMenu(menu)),
            trailingIcon: const Icon(Icons.chevron_right),
            onPressed: isBlank ? null : () => setState(() => _menu = menu),
            child: Text(_titleOf(l10n, menu)),
          ),
          ScribePromptEntry(:final prompt) => MenuItemButton(
            leadingIcon: _menu == ScribeMenu.root
                ? const Icon(Icons.checklist)
                : null,
            onPressed: isBlank ? null : () => _rewrite(room, prompt),
            child: Text(_labelOf(l10n, prompt)),
          ),
        },
    ];
  }

  Widget _encryptionNotice(L10n l10n, String? host) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _menuWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LinagoraSpacing.base * 1.5,
          vertical: LinagoraSpacing.base,
        ),
        child: Text(
          host == null || host.isEmpty
              ? l10n.scribeSentOutsideEncryption
              : l10n.scribeSentOutsideEncryptionTo(host),
          style: LinagoraTextStyle.material().bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _rewrite(ScribeRoom room, ScribePrompt prompt) async {
    final draft = widget.draft.text;
    final screen = Scaffold.maybeOf(context)?.context ?? context;
    try {
      final text = await ref
          .read(scribeControllerProvider(widget.roomId).notifier)
          .rewrite(room: room, prompt: prompt, draft: draft);
      if (!mounted) {
        _sayDropped(screen, (l10n) => l10n.scribeResultDroppedClosed);
        return;
      }
      if (widget.draft.text != draft) {
        _sayDropped(context, (l10n) => l10n.scribeResultDroppedTyped);
        return;
      }
      widget.onRewritten(text);
    } on Exception catch (e, s) {
      if (e is! ScribeException && e is! DriveException) {
        Logs().e('ScribeButton::_rewrite', e, s);
      }
      if (!mounted) return;
      final message = _failureMessage.of(L10n.of(context)!, e);
      if (message != null) TwakeSnackBar.show(context, message);
    }
  }

  void _sayDropped(BuildContext context, String Function(L10n) messageOf) {
    if (!context.mounted) return;
    TwakeSnackBar.show(context, messageOf(L10n.of(context)!));
  }

  String _titleOf(L10n l10n, ScribeMenu menu) => switch (menu) {
    ScribeMenu.root => l10n.scribe,
    ScribeMenu.improve => l10n.scribeImprove,
    ScribeMenu.tone => l10n.scribeTone,
    ScribeMenu.translate => l10n.scribeTranslate,
  };

  IconData _iconOfMenu(ScribeMenu menu) => switch (menu) {
    ScribeMenu.root || ScribeMenu.improve => Icons.auto_awesome_outlined,
    ScribeMenu.tone => Icons.edit_note,
    ScribeMenu.translate => Icons.translate,
  };

  String _labelOf(L10n l10n, ScribePrompt prompt) => switch (prompt) {
    ScribePrompt.correctGrammar => l10n.scribeCorrect,
    ScribePrompt.makeShorter => l10n.scribeMakeShorter,
    ScribePrompt.expandContext => l10n.scribeExpand,
    ScribePrompt.emojify => l10n.scribeAddEmojis,
    ScribePrompt.transformToBullets => l10n.scribeBulletPoints,
    ScribePrompt.changeToneProfessional => l10n.scribeToneProfessional,
    ScribePrompt.changeToneCasual => l10n.scribeToneCasual,
    ScribePrompt.changeTonePolite => l10n.scribeTonePolite,
    ScribePrompt.translateFrench => l10n.scribeTranslateFrench,
    ScribePrompt.translateEnglish => l10n.scribeTranslateEnglish,
    ScribePrompt.translateRussian => l10n.scribeTranslateRussian,
    ScribePrompt.translateVietnamese => l10n.scribeTranslateVietnamese,
    ScribePrompt.summarize => l10n.scribeSummarize,
  };
}
