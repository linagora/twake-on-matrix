import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

extension StringCasingExtension on String {
  String removeDiacritics() {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String str = this;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  String getShortcutNameForAvatar() {
    final words = trim().split(RegExp('\\s+'));

    if (words.isEmpty || words[0] == '') {
      return '@';
    }

    final first = words[0];
    final last = words.length > 1 ? words[1] : '';
    final codeUnits = StringBuffer();

    if (first.isNotEmpty) {
      codeUnits.writeCharCode(first.runes.first);
    }

    if (last.isNotEmpty) {
      codeUnits.writeCharCode(last.runes.first);
    }

    return codeUnits.toString().toUpperCase();
  }

  String capitalize(BuildContext context) {
    return toBeginningOfSentenceCase(this, L10n.of(context)!.localeName) ?? this;
  }

  String toTomMatrixId() {
    return '@$this:tom-dev.xyz';
  }

  bool isCurrentMatrixId(BuildContext context) {
    if (isEmpty) {
      return false;
    }
    return Matrix.of(context).client.userID == this;
  }

  List<String> getMentionsFromMessage() {
    final RegExp regex = RegExp(r"@\[([^\]]+)\]");
    final Iterable<Match> matches = regex.allMatches(this);

    final List<String> mentions = [];
    for (final Match match in matches) {
      final String? mention = match.group(0);
      if (mention != null) {
        mentions.add(mention);
      }
    }

    return mentions;
  }

  List<String> getAllMentionedUserIdsFromMessage(Room room) {
    final List<String> mentionUserIds = [];
    for (final String mention in getMentionsFromMessage()) {
      final String? userId = room.lastEvent?.room.getMention(mention);
      if (userId != null) {
        mentionUserIds.add(userId);
      }
    }

    return mentionUserIds;
  }
}
