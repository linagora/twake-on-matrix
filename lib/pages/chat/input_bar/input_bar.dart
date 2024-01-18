import 'package:emojis/emoji.dart';
import 'package:fluffychat/pages/chat/command_hints.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_list.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar_shortcut.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar_style.dart';
import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:fluffychat/presentation/mixins/paste_image_mixin.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:slugify/slugify.dart';

class InputBar extends StatelessWidget with PasteImageMixin {
  final Room? room;
  final int? minLines;
  final int? maxLines;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? typeAheadFocusNode;
  final FocusNode? rawKeyboardFocusNode;
  final TextEditingController? controller;
  final ScrollController? suggestionScrollController;
  final FocusSuggestionController focusSuggestionController;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final ValueKey? typeAheadKey;

  InputBar({
    this.room,
    this.minLines,
    this.maxLines,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.typeAheadFocusNode,
    this.controller,
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.suggestionScrollController,
    required this.focusSuggestionController,
    this.typeAheadKey,
    this.rawKeyboardFocusNode,
    Key? key,
  }) : super(key: key);

  static const debounceDuration = Duration(milliseconds: 50);

  static const debounceDurationTap = Duration(milliseconds: 100);

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
      final users = room!
          .getParticipants()
          .where((user) => user.senderId != room!.client.userID)
          .toList();
      for (final user in users) {
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

  void insertSuggestion(Map<String, String?> suggestion) {
    if (room!.isDirectChat) return;
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

  Future<void> handlePaste(BuildContext context) async {
    if (await Clipboard.instance.isReadableImageFormat() && room != null) {
      await pasteImage(context, room!);
    } else {
      await controller?.pasteText();
    }
  }

  void _onEnter(String text) {
    if (focusSuggestionController.suggestions.isNotEmpty) {
      insertSuggestion(
        focusSuggestionController
            .suggestions[focusSuggestionController.currentIndex.value],
      );
    } else {
      onSubmitted?.call(text);
    }
  }

  KeyEventResult _onBlockUpDownArrowEvent(FocusNode _, RawKeyEvent event) {
    if (event.isKeyPressed(service.LogicalKeyboardKey.arrowUp) ||
        event.isKeyPressed(service.LogicalKeyboardKey.arrowDown)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onIgnoreUpDownArrowEvent(FocusNode _, RawKeyEvent event) {
    return KeyEventResult.ignored;
  }

  void onRawKeyEvent(RawKeyEvent event) {
    if (focusSuggestionController.hasSuggestions) {
      typeAheadFocusNode?.onKey = _onBlockUpDownArrowEvent;
      if (event.isKeyPressed(service.LogicalKeyboardKey.arrowUp)) {
        focusSuggestionController.up();
      } else if (event.isKeyPressed(service.LogicalKeyboardKey.arrowDown)) {
        focusSuggestionController.down();
      }
    } else {
      typeAheadFocusNode?.onKey = _onIgnoreUpDownArrowEvent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputBarShortcuts(
      controller: controller,
      focusSuggestionController: focusSuggestionController,
      room: room,
      onEnter: _onEnter,
      child: RawKeyboardListener(
        key: typeAheadKey,
        focusNode: rawKeyboardFocusNode ?? FocusNode(),
        onKey: (event) {
          onRawKeyEvent(event);
        },
        child: TypeAheadField<Map<String, String?>>(
          direction: AxisDirection.up,
          hideOnEmpty: true,
          hideOnLoading: true,
          keepSuggestionsOnSuggestionSelected: true,
          debounceDuration: debounceDuration,
          autoFlipDirection: true,
          scrollController: suggestionScrollController,
          // show suggestions after 50ms idle time (default is 300)
          textFieldConfiguration: TextFieldConfiguration(
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofocus: autofocus,
            style: InputBarStyle.getTypeAheadTextStyle(context),
            controller: controller,
            decoration: decoration,
            focusNode: typeAheadFocusNode,
            onChanged: (text) {
              if (onChanged != null) {
                onChanged!(text);
              }
            },
            onTap: () async {
              await Future.delayed(debounceDurationTap);
              FocusScope.of(context).requestFocus(typeAheadFocusNode);
            },
            onSubmitted: PlatformInfos.isMobile
                ? (text) {
                    if (onSubmitted != null) {
                      onSubmitted!(text);
                    }
                  }
                : null,
            textCapitalization: TextCapitalization.sentences,
          ),
          suggestionsCallback: (text) {
            if (room!.isDirectChat) return {};
            final suggestions = getSuggestions(text);
            focusSuggestionController.suggestions = suggestions;
            return suggestions;
          },
          itemBuilder: (context, suggestion) => SuggestionTile(
            suggestion: suggestion,
            client: Matrix.of(context).client,
          ),
          suggestionsBoxDecoration: const SuggestionsBoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(InputBarStyle.suggestionBorderRadius),
            ),
          ),
          onSuggestionSelected: insertSuggestion,
          errorBuilder: (BuildContext context, Object? error) =>
              const SizedBox(),
          loadingBuilder: (BuildContext context) => const SizedBox.shrink(),
          // fix loading briefly flickering a dark box
          noItemsFoundBuilder: (BuildContext context) =>
              const SizedBox.shrink(),
          // fix loading briefly showing no suggestions
          layoutArchitecture: (widgets, _) => FocusSuggestionList(
            items: widgets,
            scrollController: suggestionScrollController,
            focusSuggestionController: focusSuggestionController,
          ),
        ),
      ),
    );
  }
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
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
        height: InputBarStyle.suggestionSize,
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
        height: InputBarStyle.suggestionSize,
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
        height: InputBarStyle.suggestionSize,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            MxcImage(
              uri: suggestion['mxc'] is String
                  ? Uri.parse(suggestion['mxc'] ?? '')
                  : null,
              width: InputBarStyle.suggestionAvatarSize,
              height: InputBarStyle.suggestionAvatarSize,
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
                          size: InputBarStyle.suggestionAvatarSize * 0.9,
                          fontSize:
                              InputBarStyle.suggestionAvatarFontSize * 0.9,
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
        padding: const EdgeInsetsDirectional.all(8.0),
        height: InputBarStyle.suggestionSize,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Avatar(
              mxContent: url,
              name: suggestion.tryGet<String>('displayname') ??
                  suggestion.tryGet<String>('mxid'),
              size: InputBarStyle.suggestionAvatarSize,
              fontSize: InputBarStyle.suggestionAvatarFontSize,
              client: client,
            ),
            const SizedBox(
              width: InputBarStyle.suggestionTileAvatarTextGap,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      suggestion['displayname'] ?? suggestion['mxid']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      maxLines: 1,
                      suggestion['mxid']!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container();
  }
}
