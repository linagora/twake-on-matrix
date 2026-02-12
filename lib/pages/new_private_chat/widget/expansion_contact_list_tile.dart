import 'package:dartz/dartz.dart' as dartz;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_invitation.dart';
import 'package:fluffychat/presentation/mixins/invitation_status_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/widget/contact_status_widget.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/display_name_widget.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

typedef OnExpansionListTileTap = void Function();

class ExpansionContactListTile extends StatefulWidget {
  final PresentationContact contact;
  final String highlightKeyword;
  final bool enableInvitation;
  final void Function()? onContactTap;

  const ExpansionContactListTile({
    super.key,
    required this.contact,
    this.highlightKeyword = '',
    this.enableInvitation = false,
    this.onContactTap,
  });

  @override
  State<ExpansionContactListTile> createState() =>
      _ExpansionContactListTileState();
}

class _ExpansionContactListTileState extends State<ExpansionContactListTile>
    with InvitationStatusMixin {
  @override
  void initState() {
    if (widget.enableInvitation == true) {
      getInvitationStatus(
        userId: client.userID ?? '',
        contactId: widget.contact.id ?? '',
        contact: widget.contact,
      );
    }
    super.initState();
  }

  void _handleMatrixIdNull({
    required BuildContext context,
    required PresentationContact contact,
    InvitationStatusResponse? invitationStatus,
  }) async {
    if (invitationStatus?.invitation != null &&
        invitationStatus!.invitation?.hasMatrixId == true) {
      widget.onContactTap?.call();
      return;
    }
    if (widget.contact.matrixId != null &&
        widget.contact.matrixId!.isNotEmpty) {
      widget.onContactTap?.call();
      return;
    }
    if (client.userID == null && client.userID?.isEmpty == true) return;
    final result = await showAdaptiveBottomSheet<String?>(
      context: context,
      builder: (context) => ContactsInvitation(
        contact: contact,
        userId: client.userID!,
        invitationStatus: invitationStatus,
      ),
    );

    if (result != null) {
      getInvitationNetworkStatus(
        userId: client.userID ?? '',
        contactId: widget.contact.id ?? '',
        invitationId: result,
        contact: widget.contact,
      );
    }
  }

  @override
  void dispose() {
    disposeInvitationStatus();
    super.dispose();
  }

  Client get client => Matrix.of(context).client;

  @override
  Widget build(BuildContext context) {
    return TwakeInkWell(
      onTap: _onContactTapHandler(
        context,
        widget.contact,
        getInvitationStatusNotifier.value
            .getSuccessOrNull<GetInvitationStatusSuccessState>()
            ?.invitationStatusResponse,
      ),
      child: TwakeListItem(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 8.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: FutureBuilder<Profile?>(
            key: widget.contact.matrixId != null
                ? Key(widget.contact.matrixId!)
                : null,
            future: widget.contact.status == ContactStatus.active
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
                        name: widget.contact.displayName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IntrinsicWidth(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: _displayNameWidget(
                                                snapshot.data?.displayName,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.contact.matrixId != null &&
                                          widget.contact.matrixId!
                                              .isCurrentMatrixId(context)) ...[
                                        const SizedBox(width: 8.0),
                                        TwakeChip(
                                          text: L10n.of(context)!.owner,
                                          textColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                      const SizedBox(width: 8.0),
                                      if (widget.contact.status != null &&
                                          widget.contact.status ==
                                              ContactStatus.inactive)
                                        ContactStatusWidget(
                                          status: widget.contact.status!,
                                        ),
                                    ],
                                  ),
                                ),
                                if (widget.contact.matrixId != null &&
                                    widget.contact.matrixId!.isNotEmpty) ...[
                                  HighlightText(
                                    text: widget.contact.matrixId!,
                                    searchWord: widget.highlightKeyword,
                                    style: ListItemStyle.subtitleTextStyle(
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.highlightKeyword.isNotEmpty) ...[
                                    if (widget.highlightKeyword
                                        .isPhoneNumberFormatted()) ...[
                                      _displayPhoneNumber(),
                                    ] else ...[
                                      _displayEmail(),
                                    ],
                                  ] else ...[
                                    _displayInformationDefault(),
                                  ],
                                ] else ...[
                                  _displayPhoneNumber(),
                                  _displayEmail(),
                                ],
                              ],
                            ),
                          ),
                          if (widget.contact.matrixId == null ||
                              widget.contact.matrixId!.isEmpty)
                            ValueListenableBuilder(
                              valueListenable: getInvitationStatusNotifier,
                              builder: _invitationIconBuilder,
                              child: _displayIconInvitation(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  BuildDisplayName _displayNameWidget(String? snapshotDisplayName) {
    return BuildDisplayName(
      profileDisplayName: _profileDisplayName(
        widget.contact,
        snapshotDisplayName,
      ),
      contactDisplayName: widget.contact.displayName,
      highlightKeyword: widget.highlightKeyword,
      style: ListItemStyle.titleTextStyle(fontFamily: 'Inter'),
    );
  }

  String? _profileDisplayName(
    PresentationContact contact,
    String? profileName,
  ) {
    return contact.displayName ?? profileName;
  }

  Widget _invitationIconBuilder(
    BuildContext context,
    dartz.Either<Failure, Success> status,
    Widget? child,
  ) {
    if (!widget.enableInvitation) {
      return const SizedBox();
    }

    return status.fold((failure) => child!, (success) {
      if (success is GetInvitationStatusLoadingState) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CupertinoActivityIndicator(),
          ),
        );
      }

      if (success is GetInvitationStatusSuccessState) {
        if (success.invitationStatusResponse.invitation?.hasMatrixId == true) {
          return const SizedBox();
        }
        return _displayIconInvitation(
          isExpired:
              success.invitationStatusResponse.invitation!.expiredTimeToInvite,
        );
      }

      return child!;
    });
  }

  Widget _displayIconInvitation({bool isExpired = true}) {
    return InkWell(
      onTap: () {
        _handleMatrixIdNull(
          context: context,
          contact: widget.contact,
          invitationStatus: getInvitationStatusNotifier.value
              .getSuccessOrNull<GetInvitationStatusSuccessState>()
              ?.invitationStatusResponse,
        );
      },
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.person_add_alt_rounded,
          color: isExpired
              ? LinagoraRefColors.material().primary
              : const Color(0XFF00C853),
        ),
      ),
    );
  }

  Widget _displayInformationDefault() {
    if (widget.contact.primaryPhoneNumber.isNotEmpty) {
      return HighlightText(
        text: widget.contact.primaryPhoneNumber,
        searchWord: widget.highlightKeyword,
        style: ListItemStyle.subtitleTextStyle(fontFamily: 'Inter'),
      );
    } else if (widget.contact.primaryEmail.isNotEmpty) {
      return HighlightText(
        text: widget.contact.primaryEmail,
        searchWord: widget.highlightKeyword,
        style: ListItemStyle.subtitleTextStyle(fontFamily: 'Inter'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox();
  }

  Widget _displayPhoneNumber() {
    if (widget.contact.primaryPhoneNumber.isNotEmpty) {
      return HighlightText(
        text: widget.contact.primaryPhoneNumber,
        searchWord: widget.highlightKeyword,
        style: ListItemStyle.subtitleTextStyle(fontFamily: 'Inter'),
      );
    }
    return const SizedBox();
  }

  Widget _displayEmail() {
    if (widget.contact.primaryEmail.isNotEmpty) {
      return HighlightText(
        text: widget.contact.primaryEmail,
        searchWord: widget.highlightKeyword,
        style: ListItemStyle.subtitleTextStyle(fontFamily: 'Inter'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox();
  }

  Future<Profile?> getProfile(BuildContext context) async {
    final client = Matrix.of(context).client;
    if (widget.contact.matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final profile = await client.getProfileFromUserId(
        widget.contact.matrixId!,
        getFromRooms: false,
      );
      Logs().d(
        "ExpansionContactListTile()::getProfiles(): ${profile.avatarUrl}",
      );
      return profile;
    } catch (e) {
      return Profile(
        userId: widget.contact.matrixId!,
        displayName: widget.contact.displayName,
        avatarUrl: null,
      );
    }
  }

  dynamic Function()? _onContactTapHandler(
    BuildContext context,
    PresentationContact contact,
    InvitationStatusResponse? invitationStatus,
  ) {
    if (widget.enableInvitation) {
      return () => _handleMatrixIdNull(
        context: context,
        contact: contact,
        invitationStatus: invitationStatus,
      );
    }

    if (widget.onContactTap != null) {
      return () => widget.onContactTap!.call();
    }

    return null;
  }
}
