import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ContactsTab extends StatefulWidget {
  final Widget? bottomNavigationBar;

  const ContactsTab({
    super.key,
    this.bottomNavigationBar,
  });

  @override
  State<StatefulWidget> createState() => ContactsTabController();
}

class ContactsTabController extends State<ContactsTab>
    with
        ComparablePresentationContactMixin,
        ContactsViewControllerMixin,
        WidgetsBindingObserver {
  final responsive = getIt.get<ResponsiveUtils>();

  Client get client => Matrix.of(context).client;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        initialFetchContacts(
          context: context,
          client: Matrix.of(context).client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });

    _listenFocusTextEditing();
    super.initState();
  }

  void _listenFocusTextEditing() {
    searchFocusNode.addListener(() {
      isSearchModeNotifier.value = searchFocusNode.hasFocus;
    });
  }

  void _handleMatrixIdNull({
    required BuildContext context,
    required PresentationContact contact,
  }) {
    showAdaptiveBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: LinagoraSysColors.material().outline,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
              ),
              Text(
                'Contact information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                contact.displayName ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraSysColors.material().tertiary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              if (contact.phoneNumbers != null &&
                  contact.phoneNumbers!.isNotEmpty)
                ...contact.phoneNumbers!.map(
                  (phoneNumber) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.call_outlined,
                          size: 24,
                          color: LinagoraSysColors.material().onSurface,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone number',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().onSurface,
                                  ),
                            ),
                            Text(
                              phoneNumber.phoneNumber ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (contact.emails != null && contact.emails!.isNotEmpty)
                ...contact.emails!.map(
                  (email) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 24,
                          color: LinagoraSysColors.material().onSurface,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().onSurface,
                                  ),
                            ),
                            Text(
                              email.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  void onContactTap({
    required BuildContext context,
    required String path,
    required PresentationContact contact,
  }) {
    if (contact.matrixId == null || contact.matrixId!.isEmpty) {
      _handleMatrixIdNull(
        context: context,
        contact: contact,
      );
      return;
    }
    if (contact.matrixId?.isCurrentMatrixId(context) == true) {
      goToSettingsProfile();
      return;
    }
    final roomId =
        Matrix.of(context).client.getDirectChatFromUserId(contact.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        path: path,
        contact: contact,
      );
    } else {
      context.go('/$path/$roomId');
    }
  }

  void goToSettingsProfile() {
    context.go('/rooms/profile');
  }

  void goToDraftChat({
    required BuildContext context,
    required String path,
    required PresentationContact contact,
  }) {
    if (contact.matrixId != Matrix.of(context).client.userID) {
      Router.neglect(
        context,
        () => context.go(
          '/$path/draftChat',
          extra: {
            PresentationContactConstant.receiverId: contact.matrixId ?? '',
            PresentationContactConstant.displayName: contact.displayName ?? '',
            PresentationContactConstant.status: '',
          },
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    disposeContactsMixin();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactsTabView(
        contactsController: this,
        bottomNavigationBar: widget.bottomNavigationBar,
      );
}
