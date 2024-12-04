import 'package:fluffychat/pages/search/recent_item_widget_style.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/presentation/extensions/search/presentation_search_extensions.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:fluffychat/widgets/twake_components/twake_chip.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class RecentItemWidget extends StatelessWidget {
  final PresentationSearch presentationSearch;
  final String highlightKeyword;
  final Client client;
  final void Function()? onTap;
  final double? avatarSize;

  const RecentItemWidget({
    required this.presentationSearch,
    required this.highlightKeyword,
    this.onTap,
    super.key,
    required this.client,
    this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return TwakeInkWell(
      onTap: onTap,
      child: SizedBox(
        height: RecentItemStyle.recentItemHeight,
        child: TwakeListItem(
          height: RecentItemStyle.recentItemHeight,
          child: Padding(
            padding: RecentItemStyle.paddingRecentItem,
            child: _buildInformationWidget(context),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationWidget(BuildContext context) {
    if (presentationSearch is ContactPresentationSearch) {
      return _ContactInformation(
        client: client,
        contactPresentationSearch:
            presentationSearch as ContactPresentationSearch,
        searchKeyword: highlightKeyword,
        avatarSize: avatarSize,
      );
    } else {
      final recentChatPresentationSearch =
          presentationSearch as RecentChatPresentationSearch;
      if (recentChatPresentationSearch.directChatMatrixID == null) {
        return _GroupChatInformation(
          client: client,
          recentChatPresentationSearch: recentChatPresentationSearch,
          searchKeyword: highlightKeyword,
          avatarSize: avatarSize,
        );
      } else {
        return _DirectChatInformation(
          client: client,
          recentChatPresentationSearch: recentChatPresentationSearch,
          searchKeyword: highlightKeyword,
          avatarSize: avatarSize,
        );
      }
    }
  }
}

class _GroupChatInformation extends StatelessWidget {
  final RecentChatPresentationSearch recentChatPresentationSearch;
  final Client client;
  final String? searchKeyword;
  final double? avatarSize;

  const _GroupChatInformation({
    required this.recentChatPresentationSearch,
    this.searchKeyword,
    required this.client,
    this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final actualMembersCount =
        recentChatPresentationSearch.roomSummary?.actualMembersCount ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: RecentItemStyle.avatarSize,
          child: Avatar(
            name: recentChatPresentationSearch.displayName,
            mxContent: recentChatPresentationSearch.getAvatarUriByMatrixId(
              client: client,
            ),
            size: avatarSize ?? RecentItemStyle.avatarSize,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchHighlightText(
                text: recentChatPresentationSearch.displayName ?? "",
                style: ListItemStyle.titleTextStyle(
                  fontFamily: 'Inter',
                ),
                searchWord: searchKeyword,
              ),
              Text(
                L10n.of(context)!.countMembers(actualMembersCount),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: ListItemStyle.subtitleTextStyle(
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchHighlightText extends StatelessWidget {
  final String text;
  final String? searchWord;
  final TextStyle? style;

  const _SearchHighlightText({
    required this.text,
    this.searchWord,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return HighlightText(
      text: text,
      style: style,
      searchWord: searchWord,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

class _DirectChatInformation extends StatelessWidget {
  final RecentChatPresentationSearch recentChatPresentationSearch;
  final Client client;
  final String? searchKeyword;
  final double? avatarSize;

  const _DirectChatInformation({
    required this.recentChatPresentationSearch,
    this.searchKeyword,
    required this.client,
    this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Avatar(
          name: recentChatPresentationSearch.displayName,
          mxContent: recentChatPresentationSearch.getAvatarUriByMatrixId(
            client: client,
          ),
          size: avatarSize ?? RecentItemStyle.avatarSize,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchHighlightText(
                text: recentChatPresentationSearch.displayName ?? "",
                style: ListItemStyle.titleTextStyle(
                  fontFamily: 'Inter',
                ),
                searchWord: searchKeyword,
              ),
              _SearchHighlightText(
                text: recentChatPresentationSearch.directChatMatrixID ?? "",
                style: ListItemStyle.subtitleTextStyle(
                  fontFamily: 'Inter',
                ),
                searchWord: searchKeyword,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactInformation extends StatelessWidget {
  final ContactPresentationSearch contactPresentationSearch;
  final String? searchKeyword;
  final Client client;
  final double? avatarSize;

  const _ContactInformation({
    required this.contactPresentationSearch,
    this.searchKeyword,
    required this.client,
    this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Profile?>(
          future: contactPresentationSearch.getProfile(client),
          builder: (context, snapshot) {
            return Avatar(
              mxContent: snapshot.data?.avatarUrl,
              name: contactPresentationSearch.displayName,
              size: avatarSize ?? RecentItemStyle.avatarSize,
            );
          },
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchHighlightText(
                      text: contactPresentationSearch.displayName ?? "",
                      style: ListItemStyle.titleTextStyle(
                        fontFamily: 'Inter',
                      ),
                      searchWord: searchKeyword,
                    ),
                  ),
                  if (contactPresentationSearch.matrixId != null &&
                      contactPresentationSearch.matrixId!
                          .isCurrentMatrixId(context)) ...[
                    const SizedBox(width: 8.0),
                    TwakeChip(
                      text: L10n.of(context)!.owner,
                      textColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contactPresentationSearch.matrixId != null)
                    _SearchHighlightText(
                      text: contactPresentationSearch.matrixId ?? "",
                      style: ListItemStyle.subtitleTextStyle(
                        fontFamily: 'Inter',
                      ),
                      searchWord: searchKeyword,
                    ),
                  if (contactPresentationSearch.email != null)
                    _SearchHighlightText(
                      text: contactPresentationSearch.email ?? "",
                      style: ListItemStyle.subtitleTextStyle(
                        fontFamily: 'Inter',
                      ),
                      searchWord: searchKeyword,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
