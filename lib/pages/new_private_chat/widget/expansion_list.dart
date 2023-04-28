import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/domain/state/contact/get_contacts_success.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:vrouter/vrouter.dart';

class ExpansionList extends StatefulWidget {

  final NewPrivateChatController newPrivateChatController;

  final String title;

  const ExpansionList({
    super.key, 
    required this.newPrivateChatController,
    required this.title, 
  });

  @override
  State<StatefulWidget> createState() => _ExpansionList();
}

class _ExpansionList extends State<ExpansionList> {
  bool isShow = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.newPrivateChatController;
    return StreamBuilder(
      stream: widget.newPrivateChatController.networkStreamController.stream,
      builder: (context, AsyncSnapshot<Either<Failure, GetContactsSuccess>> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final newGroupButton = _buildIconTextTileButton(
          context: context,
          onPressed: () {},
          iconData: Icons.supervisor_account_outlined,
          text: "New group chat",
        );

        final getHelpsButton = _buildIconTextTileButton(
          context: context,
          iconData: Icons.question_mark,
          onPressed: () {},
          text: "Get help",
        );

        if (snapshot.hasError || snapshot.data?.isLeft() != false) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12,),
              NoContactsFound(keyword: controller.searchKeyword),
              newGroupButton,
              getHelpsButton,
            ],
          );
        }

        final contactsList = snapshot.data!.fold(
          (failure) => <PresentationContact>[],
          (success) => success.contacts.toPresentationContacts(),
        ).toSet();

        if (contactsList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12,),
              NoContactsFound(keyword: controller.searchKeyword),
              newGroupButton,
              getHelpsButton,
            ],
          );
        }

        // widget.newPrivateChatController.setCacheContacts(contactsList, presentationContacts.contactType);
        
        final isSearchEmpty = widget.newPrivateChatController.searchKeyword.isEmpty;
        final expansionList = [
          _buildTitle(),
          if (isShow)
            for (final contact in contactsList)...[
              ExpansionContactListTile(
                contact: contact,
                onTap: () async {
                  if (contact.matrixId != null && contact.matrixId!.isNotEmpty) {
                    final roomId = await Matrix.of(context).client.startDirectChat(contact.matrixId!);
                    VRouter.of(context).toSegments(['rooms', roomId]);
                  }
                },)
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
              newGroupButton,
              getHelpsButton
            ]
          ]
        );
      },
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: LinagoraRefColors.material().neutral[40]
        )),
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
                }, tooltip: "Expand"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildIconTextTileButton({
    required BuildContext context,
    required Function()? onPressed,
    required IconData iconData,
    required String text,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
    );
  }

}