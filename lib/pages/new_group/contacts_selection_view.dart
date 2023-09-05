import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view_style.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ContactsSelectionView extends StatelessWidget {
  final ContactsSelectionController controller;

  const ContactsSelectionView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: controller.isFullScreen ? null : Colors.transparent,
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(
          isFullScreen: controller.isFullScreen,
        ),
        child: SearchableAppBar(
          focusNode: controller.searchFocusNode,
          title: controller.getTitle(context),
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: controller.getHintText(context),
          textEditingController: controller.textEditingController,
          toggleSearchMode: controller.toggleSearchMode,
          isFullScreen: controller.isFullScreen,
        ),
      ),
      body: Column(
        children: [
          SelectedParticipantsList(
            contactsSelectionController: controller,
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContact, child) {
                return Padding(
                  padding: ContactsSelectionViewStyle.getSelectionListPadding(
                    haveSelectedContact: haveSelectedContact,
                  ),
                  child: child,
                );
              },
              child: controller.contactsNotifier == null ||
                      controller.refreshController == null
                  ? null
                  : TwakeSmartRefresher(
                      controller: controller.refreshController!,
                      onRefresh: controller.fetchContacts,
                      onLoading: controller.loadMoreContacts,
                      child: ContactsSelectionList(
                        contactsNotifier: controller.contactsNotifier!,
                        selectedContactsMapNotifier:
                            controller.selectedContactsMapNotifier,
                        onSelectedContact: controller.onSelectedContact,
                        disabledContactIds: controller.disabledContactIds,
                      ),
                    ),
            ),
          ),
          if (!controller.isFullScreen) _webActionButton(context),
        ],
      ),
      floatingActionButton: controller.isFullScreen
          ? ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContacts, child) {
                if (!haveSelectedContacts) {
                  return const SizedBox.shrink();
                }
                return child!;
              },
              child: TwakeFloatingActionButton(
                icon: Icons.arrow_forward,
                onTap: () => controller.trySubmit(context),
              ),
            )
          : null,
    );
  }

  Padding _webActionButton(BuildContext context) {
    return Padding(
      padding: ContactsSelectionViewStyle.webActionsButtonMargin,
      child: SizedBox(
        height: ContactsSelectionViewStyle.webActionsButtonHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TwakeTextButton(
              onTap: () => context.pop(),
              message: L10n.of(context)!.cancel,
              paddingAll: ContactsSelectionViewStyle.webActionsButtonPaddingAll,
              margin: ContactsSelectionViewStyle.webActionsButtonMargin,
              borderHover: ContactsSelectionViewStyle.webActionsButtonBorder,
              buttonDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ContactsSelectionViewStyle.webActionsButtonBorder,
                ),
              ),
              styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LinagoraSysColors.material().primary,
                  ),
            ),
            const SizedBox(width: 8.0),
            ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContacts, _) {
                return TwakeTextButton(
                  onTap: () => haveSelectedContacts
                      ? controller.trySubmit(context)
                      : null,
                  message: L10n.of(context)!.add,
                  paddingAll:
                      ContactsSelectionViewStyle.webActionsButtonPaddingAll,
                  margin: ContactsSelectionViewStyle.webActionsButtonMargin,
                  borderHover:
                      ContactsSelectionViewStyle.webActionsButtonBorder,
                  buttonDecoration: BoxDecoration(
                    color: haveSelectedContacts
                        ? LinagoraSysColors.material().primary
                        : LinagoraStateLayer(
                            LinagoraSysColors.material().onSurface,
                          ).opacityLayer2,
                    borderRadius: BorderRadius.circular(
                      ContactsSelectionViewStyle.webActionsButtonBorder,
                    ),
                  ),
                  styleMessage:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: haveSelectedContacts
                                ? LinagoraSysColors.material().onPrimary
                                : LinagoraSysColors.material().onSurface,
                          ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
