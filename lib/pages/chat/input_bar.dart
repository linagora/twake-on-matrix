import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:emojis/emoji.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:slugify/slugify.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

import 'command_hints.dart';

class InputBar extends StatelessWidget {
  final Room? room;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final bool? autofocus;
  final bool readOnly;

  const InputBar({
    this.room,
    this.minLines,
    this.maxLines,
    this.keyboardType,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.decoration,
    this.onChanged,
    this.autofocus,
    this.textInputAction,
    this.readOnly = false,
    Key? key,
  }) : super(key: key);

  List<Map<String, String?>> getSuggestions(String text) {
    if (controller!.selection.baseOffset !=
            controller!.selection.extentOffset ||
        controller!.selection.baseOffset < 0) {
      return []; // no entries if there is selected text
    }
    final searchText =
        controller!.text.substring(0, controller!.selection.baseOffset);
    final List<Map<String, String?>> ret = <Map<String, String?>>[];
    const maxResults = 30;

    final commandMatch = RegExp(r'^/(\w*)$').firstMatch(searchText);
    if (commandMatch != null && room != null) {
      final commandSearch = commandMatch[1]!.toLowerCase();
      for (final command in room!.client.commands.keys) {
        if (command.contains(commandSearch)) {
          ret.add({
            'type': 'command',
            'name': command,
          });
        }

        if (ret.length > maxResults) return ret;
      }
    }
    final emojiMatch =
        RegExp(r'(?:\s|^):(?:([-\w]+)~)?([-\w]+)$').firstMatch(searchText);
    if (emojiMatch != null && room != null) {
      final packSearch = emojiMatch[1];
      final emoteSearch = emojiMatch[2]!.toLowerCase();
      final emotePacks = room!.getImagePacks(ImagePackUsage.emoticon);
      if (packSearch == null || packSearch.isEmpty) {
        for (final pack in emotePacks.entries) {
          for (final emote in pack.value.images.entries) {
            if (emote.key.toLowerCase().contains(emoteSearch)) {
              ret.add({
                'type': 'emote',
                'name': emote.key,
                'pack': pack.key,
                'pack_avatar_url': pack.value.pack.avatarUrl?.toString(),
                'pack_display_name': pack.value.pack.displayName ?? pack.key,
                'mxc': emote.value.url.toString(),
              });
            }
            if (ret.length > maxResults) {
              break;
            }
          }
          if (ret.length > maxResults) {
            break;
          }
        }
      } else if (emotePacks[packSearch] != null) {
        for (final emote in emotePacks[packSearch]!.images.entries) {
          if (emote.key.toLowerCase().contains(emoteSearch)) {
            ret.add({
              'type': 'emote',
              'name': emote.key,
              'pack': packSearch,
              'pack_avatar_url':
                  emotePacks[packSearch]!.pack.avatarUrl?.toString(),
              'pack_display_name':
                  emotePacks[packSearch]!.pack.displayName ?? packSearch,
              'mxc': emote.value.url.toString(),
            });
          }
          if (ret.length > maxResults) {
            break;
          }
        }
      }
      // aside of emote packs, also propose normal (tm) unicode emojis
      final matchingUnicodeEmojis = Emoji.all()
          .where(
            (element) => [element.name, ...element.keywords]
                .any((element) => element.toLowerCase().contains(emoteSearch)),
          )
          .toList();
      // sort by the index of the search term in the name in order to have
      // best matches first
      // (thanks for the hint by github.com/nextcloud/circles devs)
      matchingUnicodeEmojis.sort((a, b) {
        final indexA = a.name.indexOf(emoteSearch);
        final indexB = b.name.indexOf(emoteSearch);
        if (indexA == -1 || indexB == -1) {
          if (indexA == indexB) return 0;
          if (indexA == -1) {
            return 1;
          } else {
            return 0;
          }
        }
        return indexA.compareTo(indexB);
      });
      for (final emoji in matchingUnicodeEmojis) {
        ret.add({
          'type': 'emoji',
          'emoji': emoji.char,
          // don't include sub-group names, splitting at `:` hence
          'label': '${emoji.char} - ${emoji.name.split(':').first}',
          'current_word': ':$emoteSearch',
        });
        if (ret.length > maxResults) {
          break;
        }
      }
    }

    // It ensures that the username starts with the @ symbol,
    // is preceded by either a space or appears at the beginning of a line,
    // and captures the username (excluding the @ symbol) for further use
    const userMentionsRegex = r'(?:\s|^)@([-\w]*)$';

    final userMatch = RegExp(userMentionsRegex).firstMatch(searchText);
    if (userMatch != null && room != null) {
      final userSearch = userMatch[1]!.toLowerCase();
      for (final user in room!.getParticipants()) {
        if ((user.displayName != null &&
                (user.displayName!.toLowerCase().contains(userSearch) ||
                    slugify(user.displayName!.toLowerCase())
                        .contains(userSearch))) ||
            user.id.split(':')[0].toLowerCase().contains(userSearch)) {
          ret.add({
            'type': 'user',
            'mxid': user.id,
            'mention': user.mention,
            'displayname': user.displayName,
            'avatar_url': user.avatarUrl?.toString(),
          });
        }
        if (ret.length > maxResults) {
          break;
        }
      }
    }
    final roomMatch = RegExp(r'(?:\s|^)#([-\w]+)$').firstMatch(searchText);
    if (roomMatch != null && room != null) {
      final roomSearch = roomMatch[1]!.toLowerCase();
      for (final r in room!.client.rooms) {
        if (r.getState(EventTypes.RoomTombstone) != null) {
          continue; // we don't care about tombstoned rooms
        }
        final state = r.getState(EventTypes.RoomCanonicalAlias);
        final alias = state?.content['alias'];
        final altAlias = state?.content['alt_aliases'];
        if ((state != null &&
                ((alias is String &&
                        alias
                            .split(':')[0]
                            .toLowerCase()
                            .contains(roomSearch)) ||
                    (altAlias is List &&
                        altAlias.any(
                          (l) =>
                              l is String &&
                              l
                                  .split(':')[0]
                                  .toLowerCase()
                                  .contains(roomSearch),
                        )))) ||
            (r.name.toLowerCase().contains(roomSearch))) {
          ret.add({
            'type': 'room',
            'mxid': (r.canonicalAlias.isNotEmpty) ? r.canonicalAlias : r.id,
            'displayname': r.getLocalizedDisplayname(),
            'avatar_url': r.avatar?.toString(),
          });
        }
        if (ret.length > maxResults) {
          break;
        }
      }
    }
    return ret;
  }

  void insertSuggestion(_, Map<String, String?> suggestion) {
    final replaceText =
        controller!.text.substring(0, controller!.selection.baseOffset);
    var startText = '';
    final afterText = replaceText == controller!.text
        ? ''
        : controller!.text.substring(controller!.selection.baseOffset + 1);
    var insertText = '';
    if (suggestion['type'] == 'command') {
      insertText = '${suggestion['name']!} ';
      startText = replaceText.replaceAllMapped(
        RegExp(r'^(/\w*)$'),
        (Match m) => '/$insertText',
      );
    }
    if (suggestion['type'] == 'emoji') {
      insertText = '${suggestion['emoji']!} ';
      startText = replaceText.replaceAllMapped(
        suggestion['current_word']!,
        (Match m) => insertText,
      );
    }
    if (suggestion['type'] == 'emote' && room != null) {
      var isUnique = true;
      final insertEmote = suggestion['name'];
      final insertPack = suggestion['pack'];
      final emotePacks = room!.getImagePacks(ImagePackUsage.emoticon);
      for (final pack in emotePacks.entries) {
        if (pack.key == insertPack) {
          continue;
        }
        for (final emote in pack.value.images.entries) {
          if (emote.key == insertEmote) {
            isUnique = false;
            break;
          }
        }
        if (!isUnique) {
          break;
        }
      }
      insertText = ':${isUnique ? '' : '${insertPack!}~'}$insertEmote: ';
      startText = replaceText.replaceAllMapped(
        RegExp(r'(\s|^)(:(?:[-\w]+~)?[-\w]+)$'),
        (Match m) => '${m[1]}$insertText',
      );
    }
    if (suggestion['type'] == 'user') {
      insertText = '${suggestion['mention']!} ';

      // match and capture usernames that start with the @ symbol,
      // where the @ symbol is either preceded by a whitespace character
      // or appears at the beginning of a line.
      const insertMentionsRegex = r'(\s|^)(@[-\w]*)$';

      startText = replaceText.replaceAllMapped(
        RegExp(insertMentionsRegex),
        (Match m) => '${m[1]}$insertText',
      );
    }
    if (suggestion['type'] == 'room') {
      insertText = '${suggestion['mxid']!} ';
      startText = replaceText.replaceAllMapped(
        RegExp(r'(\s|^)(#[-\w]+)$'),
        (Match m) => '${m[1]}$insertText',
      );
    }
    if (insertText.isNotEmpty && startText.isNotEmpty) {
      controller!.text = startText + afterText;
      controller!.selection = TextSelection(
        baseOffset: startText.length,
        extentOffset: startText.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final useShortCuts = (PlatformInfos.isWeb ||
        PlatformInfos.isDesktop ||
        AppConfig.sendOnEnter);
    return Shortcuts(
      shortcuts: !useShortCuts
          ? {}
          : {
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
                  NewLineIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter): SubmitLineIntent(),
            },
      child: Actions(
        actions: !useShortCuts
            ? {}
            : {
                NewLineIntent: CallbackAction(
                  onInvoke: (i) {
                    final val = controller!.value;
                    final selection = val.selection.start;
                    final messageWithoutNewLine =
                        '${controller!.text.substring(0, val.selection.start)}\n${controller!.text.substring(val.selection.end)}';
                    controller!.value = TextEditingValue(
                      text: messageWithoutNewLine,
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: selection + 1),
                      ),
                    );
                    return null;
                  },
                ),
                SubmitLineIntent: CallbackAction(
                  onInvoke: (i) {
                    onSubmitted!(controller!.text);
                    return null;
                  },
                ),
              },
        child: TypeAheadField<Map<String, String?>>(
          direction: AxisDirection.up,
          hideOnEmpty: true,
          hideOnLoading: true,
          keepSuggestionsOnSuggestionSelected: true,
          debounceDuration: const Duration(milliseconds: 50),
          // show suggestions after 50ms idle time (default is 300)
          textFieldConfiguration: TextFieldConfiguration(
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: keyboardType!,
            textInputAction: textInputAction,
            autofocus: autofocus!,
            style: InputBarStyle.getTypeAheadTextStyle(context),
            onSubmitted: (text) {
              // fix for library for now
              // it sets the types for the callback incorrectly
              onSubmitted!(text);
            },
            controller: controller,
            decoration: decoration!,
            focusNode: focusNode,
            onChanged: (text) {
              // fix for the library for now
              // it sets the types for the callback incorrectly
              onChanged!(text);
            },
            textCapitalization: TextCapitalization.sentences,
          ),
          suggestionsCallback: getSuggestions,
          itemBuilder: (context, suggestion) => SuggestionTile(
            suggestion: suggestion,
            client: Matrix.of(context).client,
          ),
          onSuggestionSelected: (Map<String, String?> suggestion) =>
              insertSuggestion(context, suggestion),
          errorBuilder: (BuildContext context, Object? error) => Container(),
          loadingBuilder: (BuildContext context) => Container(),
          // fix loading briefly flickering a dark box
          noItemsFoundBuilder: (BuildContext context) =>
              Container(), // fix loading briefly showing no suggestions
        ),
      ),
    );
  }
}

class NewLineIntent extends Intent {}

class SubmitLineIntent extends Intent {}

class SuggestionTile extends StatelessWidget {
  const SuggestionTile({
    super.key,
    required this.suggestion,
    this.client,
  });

  final Map<String, String?> suggestion;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    if (suggestion['type'] == 'command') {
      final command = suggestion['name']!;
      final hint = commandHint(L10n.of(context)!, command);
      return Tooltip(
        message: hint,
        waitDuration: const Duration(days: 1), // don't show on hover
        child: Container(
          padding: const EdgeInsetsDirectional.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '/$command',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    if (suggestion['type'] == 'emoji') {
      final label = suggestion['label']!;
      return Tooltip(
        message: label,
        waitDuration: const Duration(days: 1), // don't show on hover
        child: Container(
          padding: const EdgeInsetsDirectional.all(4.0),
          child: Text(label, style: const TextStyle(fontFamily: 'monospace')),
        ),
      );
    }
    if (suggestion['type'] == 'emote') {
      return Container(
        padding: const EdgeInsetsDirectional.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            MxcImage(
              uri: suggestion['mxc'] is String
                  ? Uri.parse(suggestion['mxc'] ?? '')
                  : null,
              width: InputBarStyle.suggestionSize,
              height: InputBarStyle.suggestionSize,
            ),
            const SizedBox(width: 6),
            Text(suggestion['name']!),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: suggestion['pack_avatar_url'] != null ? 0.8 : 0.5,
                  child: suggestion['pack_avatar_url'] != null
                      ? Avatar(
                          mxContent: Uri.tryParse(
                            suggestion.tryGet<String>('pack_avatar_url') ?? '',
                          ),
                          name: suggestion.tryGet<String>('pack_display_name'),
                          size: InputBarStyle.suggestionSize * 0.9,
                          client: client,
                        )
                      : Text(suggestion['pack_display_name']!),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (suggestion['type'] == 'user' || suggestion['type'] == 'room') {
      final url = Uri.parse(suggestion['avatar_url'] ?? '');
      return Container(
        padding: const EdgeInsetsDirectional.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Avatar(
              mxContent: url,
              name: suggestion.tryGet<String>('displayname') ??
                  suggestion.tryGet<String>('mxid'),
              size: InputBarStyle.suggestionSize,
              client: client,
            ),
            const SizedBox(width: 6),
            Text(suggestion['displayname'] ?? suggestion['mxid']!),
          ],
        ),
      );
    }
    return Container();
  }
}

class InputBarStyle {
  static const double suggestionSize = 30;
  static TextStyle getTypeAheadTextStyle(BuildContext context) => TextStyle(
        fontSize: 15,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      );
}
