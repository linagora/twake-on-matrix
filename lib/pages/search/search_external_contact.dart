import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/model/contact/contact_type.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/pages/search/search_external_contact_style.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/widgets/search/empty_search_widget.dart';
import 'package:twake_chat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart';

class SearchExternalContactWidget extends ConsumerWidget {
  const SearchExternalContactWidget({
    super.key,
    required this.keyword,
    required this.searchController,
  });

  final String keyword;
  final SearchScreenState searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(freshMatrixUserProfileProvider(keyword));
    return switch (profile) {
      AsyncData(value: final profile?) => _ExternalContactTile(
        contact: PresentationContact(
          matrixId: keyword,
          displayName: profile.displayName ?? keyword.substring(1),
          type: ContactType.external,
        ),
        searchController: searchController,
      ),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: CenterLoadingIndicator(),
      ),
      _ => const EmptySearchWidget(),
    };
  }
}

class _ExternalContactTile extends StatelessWidget {
  const _ExternalContactTile({
    required this.contact,
    required this.searchController,
  });

  final PresentationContact contact;
  final SearchScreenState searchController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SearchExternalContactStyle.contentPadding,
      child: InkWell(
        onTap: () {
          searchController.onSearchItemTap(
            ContactPresentationSearch(
              matrixId: contact.matrixId,
              displayName: contact.displayName,
            ),
          );
        },
        borderRadius: SearchExternalContactStyle.borderRadius,
        child: ExpansionContactListTile(
          contact: contact,
          highlightKeyword: searchController.textEditingController.text,
        ),
      ),
    );
  }
}
