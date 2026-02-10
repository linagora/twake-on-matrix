import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ContactsInvitationView extends StatelessWidget {
  final PresentationContact contact;
  final ContactsInvitationController controller;

  const ContactsInvitationView({
    super.key,
    required this.contact,
    required this.controller,
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
                  onTap: () => controller.onGenerateInvitationLink(),
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
                          ...contact.phoneNumbers!.map(
                            (phoneNumber) => InkWell(
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () =>
                                  controller.onSelectContact(phoneNumber),
                              child: ValueListenableBuilder(
                                valueListenable: controller.selectedContact,
                                builder: (context, contact, _) {
                                  final isSelectedContact =
                                      contact is PresentationPhoneNumber &&
                                      contact.phoneNumber ==
                                          phoneNumber.phoneNumber;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Icon(
                                            Icons.call_outlined,
                                            size: 24,
                                            color: LinagoraSysColors.material()
                                                .tertiary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          L10n.of(
                                                            context,
                                                          )!.phoneNumber,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                color: LinagoraRefColors.material()
                                                                    .neutral[50],
                                                              ),
                                                        ),
                                                        Text(
                                                          phoneNumber
                                                              .phoneNumber,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                color:
                                                                    isSelectedContact
                                                                    ? LinagoraSysColors.material()
                                                                          .primary
                                                                    : LinagoraSysColors.material()
                                                                          .onSurface,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isSelectedContact)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color:
                                                          LinagoraSysColors.material()
                                                              .primary,
                                                    ),
                                                ],
                                              ),
                                              if (isSelectedContact) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  L10n.of(
                                                    context,
                                                  )!.selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            LinagoraRefColors.material()
                                                                .tertiary[30],
                                                      ),
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              Divider(
                                                color: LinagoraStateLayer(
                                                  LinagoraSysColors.material()
                                                      .surfaceTint,
                                                ).opacityLayer3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (contact.emails != null &&
                            contact.emails!.isNotEmpty)
                          ...contact.emails!.map(
                            (email) => InkWell(
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => controller.onSelectContact(email),
                              child: ValueListenableBuilder(
                                valueListenable: controller.selectedContact,
                                builder: (context, contact, _) {
                                  final isSelectedContact =
                                      contact is PresentationEmail &&
                                      contact.email == email.email;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Icon(
                                            Icons.email_outlined,
                                            color: LinagoraSysColors.material()
                                                .tertiary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          L10n.of(
                                                            context,
                                                          )!.email,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                color: LinagoraRefColors.material()
                                                                    .neutral[50],
                                                              ),
                                                        ),
                                                        Text(
                                                          email.email,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                color:
                                                                    isSelectedContact
                                                                    ? LinagoraSysColors.material()
                                                                          .primary
                                                                    : LinagoraSysColors.material()
                                                                          .onSurface,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isSelectedContact)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color:
                                                          LinagoraSysColors.material()
                                                              .primary,
                                                    ),
                                                ],
                                              ),
                                              if (isSelectedContact) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  L10n.of(
                                                    context,
                                                  )!.selectedEmailWillReceiveAnInvitationLinkAndInstructions,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            LinagoraRefColors.material()
                                                                .tertiary[30],
                                                      ),
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              Divider(
                                                color: LinagoraStateLayer(
                                                  LinagoraSysColors.material()
                                                      .surfaceTint,
                                                ).opacityLayer3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.selectedContact,
                  builder: (context, selectedContact, child) {
                    if (selectedContact == null) {
                      return const SizedBox.shrink();
                    }
                    return InkWell(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () => controller.onSendInvitation(selectedContact),
                      child: Padding(
                        padding: ContactsInvitationStyle.verticalPadding,
                        child: Container(
                          width: double.infinity,
                          height: ContactsInvitationStyle.heightSendButton,
                          decoration: BoxDecoration(
                            color: LinagoraSysColors.material().primary,
                            borderRadius: ContactsInvitationStyle.borderRadius,
                          ),
                          child: ValueListenableBuilder(
                            valueListenable: controller.sendInvitationNotifier,
                            builder: (context, state, child) => state.fold(
                              (failure) => child!,
                              (success) {
                                if (success is SendInvitationLoadingState) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              strokeWidth: 2,
                                              backgroundColor:
                                                  LinagoraSysColors.material()
                                                      .onPrimary,
                                            ),
                                      ),
                                    ],
                                  );
                                }
                                return child!;
                              },
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  L10n.of(context)!.sendInvitation,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: LinagoraSysColors.material()
                                            .onPrimary,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.send_outlined,
                                  color: LinagoraSysColors.material().onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
