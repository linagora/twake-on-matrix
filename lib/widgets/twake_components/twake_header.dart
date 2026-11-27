import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/presentation/extensions/contact/matrix_user_profile_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/mixins/on_account_data_listen_mixin.dart';
import 'package:twake_chat/widgets/mixins/show_dialog_mixin.dart';
import 'package:twake_chat/widgets/twake_components/twake_header_account_avatar.dart';
import 'package:twake_chat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class TwakeHeader extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onClearSelection;
  final ValueNotifier<SelectMode> selectModeNotifier;
  final ValueNotifier<List<ConversationSelectionPresentation>>
  conversationSelectionNotifier;
  final VoidCallback onClickAvatar;
  final Client client;
  final Widget? connectionStatusHeaderWidget;
  final List<Widget>? actions;

  const TwakeHeader({
    super.key,
    required this.onClearSelection,
    required this.client,
    required this.selectModeNotifier,
    required this.conversationSelectionNotifier,
    required this.onClickAvatar,
    this.connectionStatusHeaderWidget,
    this.actions,
  });

  @override
  ConsumerState<TwakeHeader> createState() => _TwakeHeaderState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(TwakeHeaderStyle.toolbarHeight);
}

class _TwakeHeaderState extends ConsumerState<TwakeHeader>
    with ShowDialogMixin, OnProfileChangeMixin {
  final ValueNotifier<Profile> currentProfileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  Future<void> getCurrentProfile() async {
    currentProfileNotifier.value = Profile(userId: '');
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;
    final data = await ref.read(matrixUserProfileProvider(userId).future);
    if (!mounted || ref.read(activeUserIdProvider) != userId) return;
    currentProfileNotifier.value = data.toProfile(userId);
  }

  @override
  void didUpdateWidget(covariant TwakeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.client != oldWidget.client &&
        Matrix.of(context).isValidActiveClient) {
      getCurrentProfile();
      onAccountDataSubscription?.cancel();
      listenOnProfileChangeStream(
        client: ref.read(matrixClientProvider),
        currentProfile: currentProfileNotifier.value,
        onProfileChanged: (newProfile) {
          currentProfileNotifier.value = newProfile;
        },
      );
    }
    if (currentProfileNotifier.value.userId.isEmpty) {
      getCurrentProfile();
    }
  }

  @override
  void dispose() {
    super.dispose();
    currentProfileNotifier.dispose();
    onAccountDataSubscription?.cancel();
  }

  @override
  void initState() {
    super.initState();
    getCurrentProfile();
    listenOnProfileChangeStream(
      client: ref.read(matrixClientProvider),
      currentProfile: currentProfileNotifier.value,
      onProfileChanged: (newProfile) {
        currentProfileNotifier.value = newProfile;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.selectModeNotifier,
      builder: (context, selectMode, _) {
        return selectMode == SelectMode.normal
            ? TwakeAppBar(
                backgroundColor: LinagoraSysColors.material().onPrimary,
                title: L10n.of(context)!.chats,
                context: context,
                connectionStatusHeaderWidget:
                    widget.connectionStatusHeaderWidget,
                actions: widget.actions,
                // The desktop rail has its own settings destination.
                leading: responsive.isDesktop(context)
                    ? null
                    : Padding(
                        padding: TwakeHeaderStyle.accountAvatarPadding,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ValueListenableBuilder(
                            valueListenable: currentProfileNotifier,
                            builder: (context, profile, _) =>
                                TwakeHeaderAccountAvatar(
                                  userId: profile.userId,
                                  name:
                                      profile.displayName ??
                                      profile.userId.localpart,
                                  avatarUrl: profile.avatarUrl,
                                  onTap: widget.onClickAvatar,
                                ),
                          ),
                        ),
                      ),
                leadingWidth: responsive.isDesktop(context)
                    ? null
                    : TwakeHeaderStyle.accountAvatarLeadingWidth,
              )
            : AppBar(
                backgroundColor: LinagoraSysColors.material().onPrimary,
                toolbarHeight: TwakeHeaderStyle.toolbarHeight,
                automaticallyImplyLeading: false,
                leadingWidth: TwakeHeaderStyle.leadingWidth,
                title: Align(
                  alignment: TwakeHeaderStyle.alignment,
                  child: Row(
                    mainAxisAlignment: responsive.isMobile(context)
                        ? TwakeHeaderStyle.mobileTitleAllignement
                        : MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: TwakeHeaderStyle.flexActions,
                        child: Padding(
                          padding: TwakeHeaderStyle.leadingPadding,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: selectMode == SelectMode.select
                                    ? widget.onClearSelection
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  TwakeHeaderStyle.closeIconSize,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: TwakeHeaderStyle.closeIconSize,
                                  color: selectMode == SelectMode.select
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : Colors.transparent,
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable:
                                    widget.conversationSelectionNotifier,
                                builder: (context, conversationSelection, _) {
                                  return Padding(
                                    padding: TwakeHeaderStyle
                                        .counterSelectionPadding,
                                    child: Text(
                                      conversationSelection.length.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color:
                                                selectMode == SelectMode.select
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant
                                                : Colors.transparent,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
              );
      },
    );
  }
}
