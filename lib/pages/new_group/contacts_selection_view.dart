import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view_style.dart';
import 'package:fluffychat/pages/new_group/widget/contact_item.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/contacts_warning_banner/contacts_warning_banner_view.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ContactsSelectionView extends StatelessWidget {
  final ContactsSelectionController controller;

  const ContactsSelectionView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: PreferredSize(
        preferredSize: controller.isFullScreen
            ? ContactsSelectionViewStyle.preferredSize(context)
            : ContactsSelectionViewStyle.maxPreferredSize(context),
        child: SearchableAppBar(
          toolbarHeight: ContactsSelectionViewStyle.maxToolbarHeight(context),
          focusNode: controller.searchFocusNode,
          title: controller.getTitle(context),
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: controller.getHintText(context),
          textEditingController: controller.textEditingController,
          openSearchBar: controller.openSearchBar,
          closeSearchBar: controller.closeSearchBar,
          isFullScreen: controller.isFullScreen,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContact, child) {
                return child!;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ContactsWarningBannerView(
                      warningBannerNotifier: controller.warningBannerNotifier,
                      closeContactsWarningBanner:
                          controller.closeContactsWarningBanner,
                      goToSettingsForPermissionActions:
                          controller.goToSettingsForPermissionActions,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SelectedParticipantsList(
                      contactsSelectionController: controller,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable:
                        controller.presentationRecentContactNotifier,
                    builder: (context, recentContacts, child) {
                      if (recentContacts.isEmpty) {
                        return child!;
                      }
                      return SliverExpandableList(
                        title: L10n.of(context)!.recent,
                        itemCount: recentContacts.length,
                        itemBuilder: (context, index) {
                          final disabled =
                              controller.disabledContactIds.contains(
                            recentContacts[index].directChatMatrixID,
                          );
                          return ContactItem(
                            contact:
                                recentContacts[index].toPresentationContact(),
                            selectedContactsMapNotifier:
                                controller.selectedContactsMapNotifier,
                            onSelectedContact: controller.onSelectedContact,
                            highlightKeyword:
                                controller.textEditingController.text,
                            disabled: disabled,
                          );
                        },
                      );
                    },
                    child: const SliverToBoxAdapter(
                      child: SizedBox(),
                    ),
                  ),
                  ContactsSelectionList(
                    presentationContactNotifier:
                        controller.presentationContactNotifier,
                    presentationRecentContactNotifier:
                        controller.presentationRecentContactNotifier,
                    selectedContactsMapNotifier:
                        controller.selectedContactsMapNotifier,
                    onSelectedContact: controller.onSelectedContact,
                    disabledContactIds: controller.disabledContactIds,
                    textEditingController: controller.textEditingController,
                  ),
                ],
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

  Widget _webActionButton(BuildContext context) {
    return Padding(
      padding: ContactsSelectionViewStyle.webActionsButtonPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TwakeTextButton(
            onTap: () => Navigator.of(context).pop(),
            message: L10n.of(context)!.cancel,
            borderHover: ContactsSelectionViewStyle.webActionsButtonBorder,
            margin: ContactsSelectionViewStyle.webActionsButtonMargin,
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
                onTap: () =>
                    haveSelectedContacts ? controller.trySubmit(context) : null,
                message: L10n.of(context)!.add,
                margin: ContactsSelectionViewStyle.webActionsButtonMargin,
                borderHover: ContactsSelectionViewStyle.webActionsButtonBorder,
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
                styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: haveSelectedContacts
                          ? LinagoraSysColors.material().onPrimary
                          : LinagoraSysColors.material()
                              .inverseSurface
                              .withOpacity(0.6),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
