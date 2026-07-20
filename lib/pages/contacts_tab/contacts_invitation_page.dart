import 'package:fluffychat/pages/contacts_tab/contacts_invitation_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ContactsInvitationPage extends StatelessWidget {
  final PresentationContact contact;
  final ContactsInvitationState state;
  final VoidCallback onGenerateInvitationLink;
  final ValueChanged<PresentationThirdPartyContact> onSelectContact;
  final ValueChanged<PresentationThirdPartyContact> onSendInvitation;

  const ContactsInvitationPage({
    super.key,
    required this.contact,
    required this.state,
    required this.onGenerateInvitationLink,
    required this.onSelectContact,
    required this.onSendInvitation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: ContactsInvitationStyle.padding,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 4,
                  margin: ContactsInvitationStyle.verticalPadding,
                  decoration: BoxDecoration(
                    color: LinagoraSysColors.material().outline,
                    borderRadius: ContactsInvitationStyle.borderRadius,
                  ),
                ),
                Text(
                  L10n.of(
                    context,
                  )!.selectAnEmailOrPhoneYouWantSendTheInvitationTo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                InkWell(
                  onTap: onGenerateInvitationLink,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          L10n.of(context)!.shareInvitationLink,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: LinagoraSysColors.material().primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.share_outlined,
                          color: LinagoraSysColors.material().primary,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contact.phoneNumbers != null &&
                            contact.phoneNumbers!.isNotEmpty)
                          ...contact.phoneNumbers!.map((phoneNumber) {
                            final selectedContact = state.selectedContact;
                            return _InvitationContactItem(
                              icon: Icons.call_outlined,
                              label: L10n.of(context)!.phoneNumber,
                              value: phoneNumber.phoneNumber,
                              selectedDescription: L10n.of(
                                context,
                              )!.selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions,
                              isSelected:
                                  selectedContact is PresentationPhoneNumber &&
                                  selectedContact.phoneNumber ==
                                      phoneNumber.phoneNumber,
                              onTap: () => onSelectContact(phoneNumber),
                            );
                          }),
                        if (contact.emails != null &&
                            contact.emails!.isNotEmpty)
                          ...contact.emails!.map((email) {
                            final selectedContact = state.selectedContact;
                            return _InvitationContactItem(
                              icon: Icons.email_outlined,
                              label: L10n.of(context)!.email,
                              value: email.email,
                              selectedDescription: L10n.of(
                                context,
                              )!.selectedEmailWillReceiveAnInvitationLinkAndInstructions,
                              isSelected:
                                  selectedContact is PresentationEmail &&
                                  selectedContact.email == email.email,
                              onTap: () => onSelectContact(email),
                            );
                          }),
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
                if (state.selectedContact != null)
                  InkWell(
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: state.sendInvitationState.isLoading
                        ? null
                        : () => onSendInvitation(state.selectedContact!),
                    child: Padding(
                      padding: ContactsInvitationStyle.verticalPadding,
                      child: Container(
                        width: double.infinity,
                        height: ContactsInvitationStyle.heightSendButton,
                        decoration: BoxDecoration(
                          color: LinagoraSysColors.material().primary,
                          borderRadius: ContactsInvitationStyle.borderRadius,
                        ),
                        child: state.sendInvitationState.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: LinagoraSysColors.material()
                                          .onPrimary,
                                    ),
                                  ),
                                ],
                              )
                            : _SendInvitationButtonContent(),
                      ),
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

class _InvitationContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selectedDescription;
  final bool isSelected;
  final VoidCallback onTap;

  const _InvitationContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedDescription,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(
                icon,
                size: 24,
                color: LinagoraSysColors.material().tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: LinagoraRefColors.material()
                                        .neutral[50],
                                  ),
                            ),
                            Text(
                              value,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: isSelected
                                        ? LinagoraSysColors.material().primary
                                        : LinagoraSysColors.material()
                                              .onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: LinagoraSysColors.material().primary,
                        ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedDescription,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LinagoraRefColors.material().tertiary[30],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(
                    color: LinagoraStateLayer(
                      LinagoraSysColors.material().surfaceTint,
                    ).opacityLayer3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendInvitationButtonContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          L10n.of(context)!.sendInvitation,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraSysColors.material().onPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.send_outlined,
          color: LinagoraSysColors.material().onPrimary,
        ),
      ],
    );
  }
}
