import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_group_action.dart';
import 'package:flutter/material.dart';

class ChatDetailsSearchAction implements ChatDetailsGroupAction {
  ChatDetailsSearchAction({required this.onSearch});

  final VoidCallback onSearch;

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.search;
  }

  @override
  IconData get icon => Icons.search;

  @override
  VoidCallback get onTap => onSearch;

  @override
  void Function(BuildContext context, TapDownDetails details)? get onTapDown =>
      null;
}
