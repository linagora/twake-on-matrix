import 'package:fluffychat/pages/contacts_tab/contacts_invitation_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ContactsInvitationView extends StatefulWidget {
  final PresentationContact contact;
  final void Function(PresentationThirdPartyContact)? onSendInvitation;

  const ContactsInvitationView({
    super.key,
    required this.contact,
    this.onSendInvitation,
  });

  @override
  State<ContactsInvitationView> createState() => _ContactsInvitationViewState();
}

class _ContactsInvitationViewState extends State<ContactsInvitationView> {
  final ValueNotifier<PresentationThirdPartyContact?> _selectedContact =
      ValueNotifier(null);

  void _onSelectContact(PresentationThirdPartyContact contact) {
    if (_selectedContact.value == null) {
      _selectedContact.value = contact;
    } else {
      if (_selectedContact.value is PresentationPhoneNumber &&
          contact is PresentationPhoneNumber) {
        final currentPhoneContact =
            _selectedContact.value as PresentationPhoneNumber;
        if (currentPhoneContact.phoneNumber != contact.phoneNumber) {
          _selectedContact.value = contact;
        } else {
          _selectedContact.value = null;
        }
      } else if (_selectedContact.value is PresentationEmail &&
          contact is PresentationEmail) {
        final currentEmailContact = _selectedContact.value as PresentationEmail;
        if (currentEmailContact.email != contact.email) {
          _selectedContact.value = contact;
        } else {
          _selectedContact.value = null;
        }
      } else {
        _selectedContact.value = contact;
      }
    }
  }

  //TODO: Impl later with Invitation
  // void _onSendInvitation(PresentationThirdPartyContact contact) {
  //   widget.onSendInvitation?.call(contact);
  //   Navigator.pop(context);
  // }

  void _onSelectContactDefault(PresentationContact contact) {
    if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
      _onSelectContact(contact.phoneNumbers!.first);
      return;
    }

    if (contact.emails != null && contact.emails!.isNotEmpty) {
      _onSelectContact(contact.emails!.first);
      return;
    }
  }

  @override
  void initState() {
    _onSelectContactDefault(widget.contact);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              L10n.of(context)!.selectAnEmailOrPhoneYouWantSendTheInvitationTo,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.contact.phoneNumbers != null &&
                        widget.contact.phoneNumbers!.isNotEmpty)
                      ...widget.contact.phoneNumbers!.map(
                        (phoneNumber) => TwakeInkWell(
                          onTap: () => _onSelectContact(phoneNumber),
                          child: ValueListenableBuilder(
                            valueListenable: _selectedContact,
                            builder: (context, contact, _) {
                              final isSelectedContact =
                                  contact is PresentationPhoneNumber &&
                                      contact.phoneNumber ==
                                          phoneNumber.phoneNumber;
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: isSelectedContact ? 8 : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Icon(
                                        Icons.call_outlined,
                                        size: 24,
                                        color: LinagoraSysColors.material()
                                            .onSurface,
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      L10n.of(context)!
                                                          .phoneNumber,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color: LinagoraSysColors
                                                                    .material()
                                                                .onSurface,
                                                          ),
                                                    ),
                                                    Text(
                                                      phoneNumber.phoneNumber,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge
                                                          ?.copyWith(
                                                            color: LinagoraRefColors
                                                                    .material()
                                                                .neutral[50],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelectedContact)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: LinagoraSysColors
                                                          .material()
                                                      .primary,
                                                ),
                                            ],
                                          ),
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
                    if (widget.contact.emails != null &&
                        widget.contact.emails!.isNotEmpty)
                      ...widget.contact.emails!.map(
                        (email) => TwakeInkWell(
                          onTap: () => _onSelectContact(email),
                          child: ValueListenableBuilder(
                            valueListenable: _selectedContact,
                            builder: (context, contact, _) {
                              final isSelectedContact =
                                  contact is PresentationEmail &&
                                      contact.email == email.email;
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: isSelectedContact ? 8 : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Icon(
                                        Icons.email_outlined,
                                        color: LinagoraSysColors.material()
                                            .onSurface,
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      L10n.of(context)!.email,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color: LinagoraSysColors
                                                                    .material()
                                                                .onSurface,
                                                          ),
                                                    ),
                                                    Text(
                                                      email.email,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge
                                                          ?.copyWith(
                                                            color: LinagoraRefColors
                                                                    .material()
                                                                .neutral[50],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelectedContact)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: LinagoraSysColors
                                                          .material()
                                                      .primary,
                                                ),
                                            ],
                                          ),
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
            //TODO: Impl later with Invitation
            // ValueListenableBuilder(
            //   valueListenable: _selectedContact,
            //   builder: (context, selectedContact, child) {
            //     if (selectedContact == null) {
            //       return const SizedBox.shrink();
            //     }
            //     return TwakeInkWell(
            //       onTap: () => _onSendInvitation(selectedContact),
            //       child: Padding(
            //         padding: ContactsInvitationStyle.verticalPadding,
            //         child: Container(
            //           width: double.infinity,
            //           height: ContactsInvitationStyle.heightSendButton,
            //           decoration: BoxDecoration(
            //             color: LinagoraSysColors.material().primary,
            //             borderRadius: ContactsInvitationStyle.borderRadius,
            //           ),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Text(
            //                 L10n.of(context)!.sendInvitation,
            //                 style: Theme.of(context)
            //                     .textTheme
            //                     .labelLarge
            //                     ?.copyWith(
            //                       color: LinagoraSysColors.material().onPrimary,
            //                     ),
            //               ),
            //               const SizedBox(width: 8),
            //               Icon(
            //                 Icons.send_outlined,
            //                 color: LinagoraSysColors.material().onPrimary,
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
