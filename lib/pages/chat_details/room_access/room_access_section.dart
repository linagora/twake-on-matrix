import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_controller.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';

class RoomAccessSection extends ConsumerWidget {
  const RoomAccessSection({
    super.key,
    required this.roomId,
    required this.draft,
  });

  final String roomId;

  final ValueNotifier<RoomAccessDraft> draft;

  static const EdgeInsets _textPadding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 2,
    vertical: LinagoraSpacing.base,
  );

  // Aligns the switch row with the radio items above it.
  static const EdgeInsets _togglePadding = EdgeInsets.all(
    LinagoraSpacing.base * 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(roomAccessControllerProvider(roomId)).value;
    if (saved == null) return const SizedBox.shrink();
    final l10n = L10n.of(context)!;
    final textStyle = LinagoraTextStyle.material().bodySmall.copyWith(
      color: LinagoraSysColors.material().tertiary,
    );
    final rules = saved.offeredJoinRules;
    return ValueListenableBuilder<RoomAccessDraft>(
      valueListenable: draft,
      builder: (context, chosen, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinagoraSectionHeader(label: l10n.roomAccessTitle),
          if (saved.joinRule == null)
            Padding(
              padding: _textPadding,
              child: Text(l10n.roomAccessRestricted, style: textStyle),
            )
          else
            for (final rule in rules)
              LinagoraRadioItem(
                key: ValueKey(rule),
                title: _ruleTitle(l10n, rule),
                selected: chosen.joinRuleOn(saved) == rule,
                showDivider: rule != rules.last,
                onTap: () => draft.value = chosen.choose(rule),
              ),
          Padding(
            padding: _textPadding,
            child: Text(
              saved.isEncrypted
                  ? l10n.roomAccessEncrypted
                  : l10n.roomAccessHelp,
              style: textStyle,
            ),
          ),
          if (saved.offersListing)
            LinagoraSettingItem.selectable(
              title: l10n.roomAccessListed,
              subtitle: l10n.roomAccessListedHelp,
              subtitleMaxLines: null,
              padding: _togglePadding,
              value: chosen.isListedOn(saved),
              onChanged: (isListed) =>
                  draft.value = chosen.copyWith(isListed: isListed),
            ),
        ],
      ),
    );
  }

  String _ruleTitle(L10n l10n, JoinRuleChoice rule) => switch (rule) {
    JoinRuleChoice.invite => l10n.roomAccessInvite,
    JoinRuleChoice.knock => l10n.roomAccessKnock,
    JoinRuleChoice.public => l10n.roomAccessPublic,
  };
}
