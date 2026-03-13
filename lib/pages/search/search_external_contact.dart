import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_external_contact_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:matrix/matrix.dart';

class SearchExternalContactWidget extends StatefulWidget {
  const SearchExternalContactWidget({
    super.key,
    required this.keyword,
    required this.searchController,
  });

  final String keyword;
  final SearchController searchController;

  @override
  State<SearchExternalContactWidget> createState() =>
      _SearchExternalContactWidgetState();
}

class _SearchExternalContactWidgetState
    extends State<SearchExternalContactWidget> {
  Future<Profile>? _profileFuture;
  String? _currentKeyword;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProfileIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SearchExternalContactWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword) {
      _fetchProfileIfNeeded();
    }
  }

  void _fetchProfileIfNeeded() {
    if (_currentKeyword != widget.keyword) {
      _currentKeyword = widget.keyword;
      final client = Matrix.of(context).client;
      _profileFuture = client.getProfileFromUserId(
        widget.keyword,
        getFromRooms: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 48),
            child: CenterLoadingIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const EmptySearchWidget();
        }

        final profile = snapshot.data!;
        final newContact = PresentationContact(
          matrixId: widget.keyword,
          displayName: profile.displayName ?? widget.keyword.substring(1),
          type: ContactType.external,
        );

        return Padding(
          padding: SearchExternalContactStyle.contentPadding,
          child: InkWell(
            onTap: () {
              widget.searchController.onSearchItemTap(
                ContactPresentationSearch(
                  matrixId: newContact.matrixId,
                  displayName: newContact.displayName,
                ),
              );
            },
            borderRadius: SearchExternalContactStyle.borderRadius,
            child: ExpansionContactListTile(
              contact: newContact,
              highlightKeyword:
                  widget.searchController.textEditingController.text,
            ),
          ),
        );
      },
    );
  }
}
