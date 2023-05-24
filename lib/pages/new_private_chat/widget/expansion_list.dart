import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:vrouter/vrouter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ExpansionList extends StatefulWidget {

  final NewPrivateChatController newPrivateChatController;

  const ExpansionList({
    super.key, 
    required this.newPrivateChatController,
  });

  @override
  State<StatefulWidget> createState() => _ExpansionList();
}

class _ExpansionList extends State<ExpansionList> {
  bool isShow = true;

  @override
  Widget build(BuildContext context) {
    final searchContactsController = widget.newPrivateChatController.searchContactsController;
    return StreamBuilder<Either<Failure, GetContactsSuccess>>(
      stream: widget.newPrivateChatController.networkStreamController.stream,
      builder: (context, AsyncSnapshot<Either<Failure, GetContactsSuccess>> snapshot) {

        final newGroupButton = _buildIconTextTileButton(
          context: context,
          onPressed: () => VRouter.of(context).to('/newgroup'),
          iconData: Icons.supervisor_account_outlined,
          text: L10n.of(context)!.newGroupChat,
        );

        final getHelpsButton = _buildIconTextTileButton(
          context: context,
          iconData: Icons.question_mark,
          onPressed: () {},
          text: L10n.of(context)!.getHelp,
        );

        final moreListTile = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Text(L10n.of(context)!.more,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.1,
              color: LinagoraRefColors.material().neutral[40],
            ),),
        );

        if (!snapshot.hasData || searchContactsController.searchKeyword.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              newGroupButton,
              getHelpsButton
            ],
          );
        }

        if (snapshot.hasError || snapshot.data?.isLeft() != false) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12,),
              NoContactsFound(keyword: searchContactsController.searchKeyword),
              moreListTile,
              newGroupButton,
              getHelpsButton,
            ],
          );
        }

        final contactsList = snapshot.data!.fold(
          (failure) => <PresentationContact>[],
          (success) => success.contacts.expand((contact) => contact.toPresentationContacts()),
        ).toSet();

        if (contactsList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12,),
              NoContactsFound(keyword: searchContactsController.searchKeyword),
              moreListTile,
              newGroupButton,
              getHelpsButton,
            ],
          );
        }

        final isSearchEmpty = searchContactsController.searchKeyword.isEmpty;
        final expansionList = [
          const SizedBox(height: 4,),
          _buildTitle(contactsList.length),
          if (isShow)
            for (final contact in contactsList)...[
              InkWell(
                borderRadius: BorderRadius.circular(16.0),
                child: ExpansionContactListTile(
                  contact: contact,
                  onTap: () async {
                    if (contact.displayName != null && contact.displayName!.isNotEmpty) {
                      final roomId = await Matrix.of(context).client.startDirectChat(contact.displayName!.toTomMatrixId());
                      VRouter.of(context).toSegments(['rooms', roomId]);
                    }
                  },),
              )
            ]
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSearchEmpty)...[
              newGroupButton,
              for(final child in expansionList)...[
                child
              ],
              getHelpsButton
            ] else ...[
              for(final child in expansionList)...[
                child
              ],
              moreListTile,
              newGroupButton,
              getHelpsButton
            ]
          ]
        );
      },
    );
  }

  Widget _buildTitle(int countContacts) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Text(L10n.of(context)!.countTwakeUsers(countContacts),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LinagoraRefColors.material().neutral[40],
            ),),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TwakeIconButton(
                  paddingAll: 6.0,
                  buttonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  icon: isShow ? Icons.expand_less : Icons.expand_more,
                  onPressed: () {
                    setState(() {
                      isShow = !isShow;
                    });
                  }, tooltip: isShow 
                    ? L10n.of(context)!.shrink 
                    : L10n.of(context)!.expand),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconTextTileButton({
    required BuildContext context,
    required Function()? onPressed,
    required IconData iconData,
    required String text,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: 56.0,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(iconData, color: Theme.of(context).colorScheme.primary),
                ),
                Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -0.15
                ),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}