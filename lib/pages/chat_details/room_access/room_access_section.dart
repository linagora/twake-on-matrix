import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_controller.dart';

class RoomAccessSection extends ConsumerWidget {
  const RoomAccessSection({super.key, required this.roomId});

  final String roomId;

  static const EdgeInsets _textPadding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 2,
    vertical: LinagoraSpacing.base,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = roomAccessControllerProvider(roomId);
    final access = ref.watch(provider).value;
    if (access == null) return const SizedBox.shrink();
    final l10n = L10n.of(context)!;
    final textStyle = LinagoraTextStyle.material().bodySmall.copyWith(
      color: LinagoraSysColors.material().tertiary,
    );
    final rules = access.offeredJoinRules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinagoraSectionHeader(label: l10n.roomAccessTitle),
        if (access.joinRule == null)
          Padding(
            padding: _textPadding,
            child: Text(l10n.roomAccessRestricted, style: textStyle),
          )
        else
          for (final rule in rules)
            LinagoraRadioItem(
              key: ValueKey(rule),
              title: _ruleTitle(l10n, rule),
              selected: access.joinRule == rule,
              showDivider: rule != rules.last,
              onTap: () => ref.read(provider.notifier).chooseJoinRule(rule),
            ),
        Padding(
          padding: _textPadding,
          child: Text(
            access.saved.isEncrypted
                ? l10n.roomAccessEncrypted
                : l10n.roomAccessHelp,
            style: textStyle,
          ),
        ),
        if (access.showsListing)
          LinagoraSettingItem.selectable(
            title: l10n.roomAccessListed,
            subtitle: l10n.roomAccessListedHelp,
            subtitleMaxLines: null,
            value: access.isListed,
            onChanged: ref.read(provider.notifier).setListed,
          ),
      ],
    );
  }

  String _ruleTitle(L10n l10n, JoinRuleChoice rule) => switch (rule) {
    JoinRuleChoice.invite => l10n.roomAccessInvite,
    JoinRuleChoice.knock => l10n.roomAccessKnock,
    JoinRuleChoice.public => l10n.roomAccessPublic,
  };
}
