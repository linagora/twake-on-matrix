import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';

class ExpansionList extends StatelessWidget {
  final ValueNotifier<List<PresentationContact>> presentationContactsNotifier;
  final ValueNotifier<bool> isShowContactsNotifier;
  final Function() goToNewGroupChat;
  final Function() toggleContactsList;
  final Function(BuildContext context, PresentationContact contact)
      onExternalContactTap;
  final Function(BuildContext context, PresentationContact contact)
      onContactTap;
  final TextEditingController textEditingController;

  const ExpansionList({
    super.key,
    required this.presentationContactsNotifier,
    required this.isShowContactsNotifier,
    required this.goToNewGroupChat,
    required this.toggleContactsList,
    required this.onExternalContactTap,
    required this.onContactTap,
    required this.textEditingController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: presentationContactsNotifier,
      builder: (context, presentationContacts, child) {
        if (presentationContacts.isEmpty &&
            textEditingController.text.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 12,
              ),
              NoContactsFound(
                keyword: textEditingController.text,
              ),
              _MoreListTile(),
              _NewGroupButton(
                onPressed: goToNewGroupChat,
              ),
              _GetHelpButton(),
            ],
          );
        }

        final isSearchEmpty = textEditingController.text.isEmpty;
        final expansionList = [
          const SizedBox(
            height: 4,
          ),
          _buildTitle(context, presentationContacts.length),
          ValueListenableBuilder<bool>(
            valueListenable: isShowContactsNotifier,
            builder: ((context, isShow, child) {
              if (!isShow) {
                return const SizedBox.shrink();
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: presentationContacts.length,
                itemBuilder: (context, index) {
                  final contact = presentationContacts[index];
                  return InkWell(
                    onTap: () {
                      onContactTap(
                        context,
                        contact,
                      );
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: ExpansionContactListTile(
                      contact: contact,
                      highlightKeyword: textEditingController.text,
                    ),
                  );
                },
              );
            }),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSearchEmpty) ...[
              _NewGroupButton(
                onPressed: goToNewGroupChat,
              ),
              for (final child in expansionList) ...[child],
              _GetHelpButton(),
            ] else ...[
              for (final child in expansionList) ...[child],
              _MoreListTile(),
              _NewGroupButton(
                onPressed: goToNewGroupChat,
              ),
              _GetHelpButton(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, int countContacts) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Text(
            L10n.of(context)!.twakeUsers,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LinagoraRefColors.material().neutral[40],
                ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isShowContactsNotifier,
                  builder: (context, isShow, child) {
                    return TwakeIconButton(
                      paddingAll: 6.0,
                      buttonDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      icon: isShow ? Icons.expand_less : Icons.expand_more,
                      onTap: toggleContactsList,
                      tooltip: isShow
                          ? L10n.of(context)!.shrink
                          : L10n.of(context)!.expand,
                    );
                  },
                ),
              ],
            ),
          ),
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
                  child: Icon(
                    iconData,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewGroupButton extends StatelessWidget {
  final Function() onPressed;

  const _NewGroupButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _IconTextTileButton(
      context: context,
      onPressed: onPressed,
      iconData: Icons.supervisor_account_outlined,
      text: L10n.of(context)!.newGroupChat,
    );
  }
}

class _GetHelpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _IconTextTileButton(
      context: context,
      onPressed: () => {},
      iconData: Icons.question_mark,
      text: L10n.of(context)!.getHelp,
    );
  }
}

class _MoreListTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        L10n.of(context)!.more,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.1,
              color: LinagoraRefColors.material().neutral[40],
            ),
      ),
    );
  }
}
