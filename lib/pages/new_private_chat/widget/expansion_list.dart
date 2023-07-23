import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_network_contact_success.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

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

  @override
  Widget build(BuildContext context) {
    final searchContactsController = widget.newPrivateChatController.searchContactsController;
    final fetchContactsController = widget.newPrivateChatController.fetchContactsController;
    return StreamBuilder<Either<Failure, Success>>(
      stream: widget.newPrivateChatController.streamController.stream,
      builder: (context, snapshot) {
        final newGroupButton = _IconTextTileButton(
          context: context,
          onPressed: () => widget.newPrivateChatController.goToNewGroupChat(),
          iconData: Icons.supervisor_account_outlined,
          text: L10n.of(context)!.newGroupChat
        );

        final getHelpsButton = _IconTextTileButton(
          context: context,
          onPressed:() => {},
          iconData: Icons.question_mark,
          text: L10n.of(context)!.getHelp
        );
        if (snapshot.data != null) {
          return snapshot.data!.fold(
            (failure) => const SizedBox.shrink(),
            (success) {
              Logs().d('ExpansionList success: $success');
              final moreListTile = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Text(L10n.of(context)!.more,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 0.1,
                    color: LinagoraRefColors.material().neutral[40],
                  )));

              if (success is GetNetworkContactSuccess && success.contacts.isEmpty) {
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

              final contactsList = fetchContactsController.getContactsFromFetchStream(snapshot.data!);

              if (contactsList.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    NoContactsFound(keyword: searchContactsController.searchKeyword),
                    moreListTile,
                    newGroupButton,
                    getHelpsButton,
                  ],
                );
              }

              final isSearchEmpty = searchContactsController.searchKeyword.isEmpty;

              final expansionList = [
                const SizedBox(height: 4),
                _buildTitle(contactsList.length),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.newPrivateChatController.isShowContactsNotifier,
                  builder: ((context, isShow, child) {
                    if (!isShow) {
                      return const SizedBox.shrink();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contactsList.length,
                      itemBuilder: (context, index) {
                        final contact = contactsList[index];
                        return InkWell(
                          onTap: () {
                            widget.newPrivateChatController.goToChatScreen(context: context, contact: contact);
                          },
                          borderRadius: BorderRadius.circular(16.0),
                          child: ExpansionContactListTile(contact: contact),
                        );
                      },
                    );
                  }),
                ),
                ValueListenableBuilder(
                  valueListenable: searchContactsController.isSearchModeNotifier,
                  builder: (context, isSearchMode, child) {
                    if (isSearchMode) {
                        return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder(
                      valueListenable: widget.newPrivateChatController.isShowContactsNotifier,
                      builder: (context, isShow, child) {
                        if (!isShow) {
                          return const SizedBox.shrink();
                        }
                        return ValueListenableBuilder(
                          valueListenable: fetchContactsController.haveMoreCountactsNotifier,
                          builder: (context, haveMoreContacts, child) {
                            if (haveMoreContacts) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          }
                        );
                      }
                    );
                  }
                ),
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
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              newGroupButton,
              const LoadingContactWidget(),
              getHelpsButton
            ],
          );
        }
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
                ValueListenableBuilder<bool>(
                  valueListenable: widget.newPrivateChatController.isShowContactsNotifier,
                  builder: (context, isShow, child) {
                    return TwakeIconButton(
                      paddingAll: 6.0,
                      buttonDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      icon: isShow ? Icons.expand_less : Icons.expand_more,
                      onPressed: () {
                        widget.newPrivateChatController.toggleContactsList();
                      }, tooltip: isShow 
                        ? L10n.of(context)!.shrink 
                        : L10n.of(context)!.expand);
                  }
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _IconTextTileButton extends StatelessWidget {
  const _IconTextTileButton({
    required this.context,
    required this.onPressed,
    required this.iconData,
    required this.text,
  });

  final BuildContext context;
  final Function()? onPressed;
  final IconData iconData;
  final String text;

  @override
  Widget build(BuildContext context) {
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