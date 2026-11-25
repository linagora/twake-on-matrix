import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/pages/scribe/scribe_controller.dart';
import 'package:twake_chat/pages/scribe/scribe_failure_message.dart';
import 'package:twake_chat/pages/scribe/scribe_menu.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

/// The Scribe of the composer: its menu rewrites the whole [draft], and the
/// result replaces it through [onRewritten]. Hidden where the room does not
/// offer the Scribe or the workplace is not configured.
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
  static const double _menuWidth = 200;

  final _menuController = MenuController();
  ScribeMenu _menu = ScribeMenu.root;

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(
      driveConfigProvider.select((config) => config.isEnabled),
    );
    // Without a workplace the room is not even read.
    if (!isConfigured) return const SizedBox.shrink();
    final room = ref.watch(scribeRoomProvider(widget.roomId)).value;
    if (room == null || !room.offersScribe) {
      return const SizedBox.shrink();
    }
    final isRewriting = ref.watch(scribeControllerProvider(widget.roomId));
    // The workplace the draft goes to, known once the user signed in.
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
        height: ChatInputRowStyle.chatInputRowHeight,
        child: isRewriting
            ? const Padding(
                padding: EdgeInsets.all(
                  (ChatInputRowStyle.chatInputRowHeight - _progressSize) / 2,
                ),
                child: SizedBox.square(
                  dimension: _progressSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: l10n.scribe,
                iconSize: ChatInputRowStyle.chatInputRowMoreBtnSize,
                icon: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _open,
              ),
      ),
    );
  }

  void _open() {
    // The menu sits above the composer, not under the keyboard.
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
            // Correct and Summarize share the design's checklist icon.
            leadingIcon: _menu == ScribeMenu.root
                ? const Icon(Icons.checklist)
                : null,
            onPressed: isBlank ? null : () => _rewrite(room, prompt),
            child: Text(_labelOf(l10n, prompt)),
          ),
        },
    ];
  }

  /// In an encrypted room the draft leaves the encryption: say where to.
  Widget _encryptionNotice(L10n l10n, String? host) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _menuWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          host == null || host.isEmpty
              ? l10n.scribeSentOutsideEncryption
              : l10n.scribeSentOutsideEncryptionTo(host),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _rewrite(ScribeRoom room, ScribePrompt prompt) async {
    final draft = widget.draft.text;
    try {
      final text = await ref
          .read(scribeControllerProvider(widget.roomId).notifier)
          .rewrite(room: room, prompt: prompt, draft: draft);
      // The user typed meanwhile: their text wins.
      if (!mounted || widget.draft.text != draft) return;
      widget.onRewritten(text);
    } on Exception catch (e, s) {
      // The sources log the failures they map; an unmapped one is a bug.
      if (e is! ScribeException && e is! DriveException) {
        Logs().e('ScribeButton::_rewrite', e, s);
      }
      if (!mounted) return;
      final message = _failureMessage.of(L10n.of(context)!, e);
      if (message != null) TwakeSnackBar.show(context, message);
    }
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
