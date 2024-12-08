import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/widget/contact_status_widget.dart';
import 'package:fluffychat/utils/display_name_widget.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

typedef OnExpansionListTileTap = void Function();

class ExpansionContactListTile extends StatelessWidget {
  final PresentationContact contact;
  final String highlightKeyword;

  const ExpansionContactListTile({
    super.key,
    required this.contact,
    this.highlightKeyword = '',
  });

  @override
  Widget build(BuildContext context) {
    return TwakeListItem(
      child: Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 8.0, top: 8.0, bottom: 8.0),
        child: FutureBuilder<Profile?>(
          key: contact.matrixId != null ? Key(contact.matrixId!) : null,
          future: contact.status == ContactStatus.active
              ? getProfile(context)
              : null,
          builder: (context, snapshot) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: IgnorePointer(
                    child: Avatar(
                      mxContent: snapshot.data?.avatarUrl,
                      name: contact.displayName,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicWidth(
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: BuildDisplayName(
                                      profileDisplayName:
                                          snapshot.data?.displayName,
                                      contactDisplayName: contact.displayName,
                                      highlightKeyword: highlightKeyword,
                                      style: ListItemStyle.titleTextStyle(
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (contact.matrixId != null &&
                                contact.matrixId!
                                    .isCurrentMatrixId(context)) ...[
                              const SizedBox(width: 8.0),
                              TwakeChip(
                                text: L10n.of(context)!.owner,
                                textColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ],
                            const SizedBox(width: 8.0),
                            if (contact.status != null &&
                                contact.status == ContactStatus.inactive)
                              ContactStatusWidget(
                                status: contact.status!,
                              ),
                          ],
                        ),
                      ),
                      if (contact.matrixId != null &&
                          (contact.email == null ||
                              contact.phoneNumber == null))
                        HighlightText(
                          text: contact.matrixId!,
                          searchWord: highlightKeyword,
                          style: ListItemStyle.subtitleTextStyle(
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (contact.email != null)
                        HighlightText(
                          text: contact.email!,
                          searchWord: highlightKeyword,
                          style: ListItemStyle.subtitleTextStyle(
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (contact.phoneNumber != null)
                        HighlightText(
                          text: contact.phoneNumber!,
                          searchWord: highlightKeyword,
                          style: ListItemStyle.subtitleTextStyle(
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Profile?> getProfile(BuildContext context) async {
    final client = Matrix.of(context).client;
    if (contact.matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final profile = await client.getProfileFromUserId(
        contact.matrixId!,
        getFromRooms: false,
      );
      Logs()
          .d("ExpansionContactListTile()::getProfiles(): ${profile.avatarUrl}");
      return profile;
    } catch (e) {
      return Profile(
        userId: contact.matrixId!,
        displayName: contact.displayName,
        avatarUrl: null,
      );
    }
  }
}
