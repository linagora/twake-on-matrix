import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_blocked_users/settings_blocked_users_search_state.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'settings_blocked_users_view.dart';

class BlockedUsers extends StatefulWidget {
  final String? initialUserId;

  const BlockedUsers({super.key, this.initialUserId});

  @override
  SettingsIgnoreListController createState() => SettingsIgnoreListController();
}

class SettingsIgnoreListController extends State<BlockedUsers>
    with SearchDebouncerMixin {
  Client get client => Matrix.read(context).client;

  final responsiveUtils = getIt.get<ResponsiveUtils>();

  StreamSubscription? ignoredUsersStreamSub;

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<Either<Failure, Success>> searchUserResults =
      ValueNotifier<Either<Failure, Success>>(
        Right(BlockedUsersSearchInitialState()),
      );

  final List<Profile> blockedUsers = [];

  void onBack() {
    context.go('/rooms/security');
  }

  Future<void> initialBlockedUsers() async {
    TwakeDialog.showLoadingDialog(context);

    if (client.ignoredUsers.isEmpty) {
      searchUserResults.value = const Left(
        BlockedUsersSearchEmptyState(keyword: ''),
      );
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    for (final userId in client.ignoredUsers) {
      try {
        final user = await client.getProfileFromUserId(
          userId,
          getFromRooms: false,
        );
        blockedUsers.add(user);
      } catch (e) {
        Logs().e(
          "SettingsIgnoreListController::initialBlockedUsers: Error fetching profile for userId $userId: $e",
        );
      }
    }
    if (blockedUsers.isNotEmpty) {
      searchUserResults.value = Right(
        BlockedUsersSearchSuccessState(blockedUsers: blockedUsers, keyword: ''),
      );
    } else {
      searchUserResults.value = const Left(
        BlockedUsersSearchEmptyState(keyword: ''),
      );
    }
    TwakeDialog.hideLoadingDialog(context);
  }

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = Right(
        BlockedUsersSearchSuccessState(blockedUsers: blockedUsers, keyword: ''),
      );
      return;
    }

    final searchResults = blockedUsers.where((user) {
      return (user.displayName ?? '').toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          (user.userId).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    Logs().d(
      "BlockedUsersController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = Left(
        BlockedUsersSearchEmptyState(keyword: searchTerm),
      );
      return;
    }

    searchUserResults.value = Right(
      BlockedUsersSearchSuccessState(
        blockedUsers: searchResults,
        keyword: searchTerm,
      ),
    );
  }

  void listenBlockedUsers() {
    ignoredUsersStreamSub = client.ignoredUsersStream.listen((value) async {
      await refreshBlockedUsers();
    });
  }

  Future<void> refreshBlockedUsers() async {
    TwakeDialog.showLoadingDialog(context);
    searchUserResults.value = Right(BlockedUsersSearchInitialState());

    if (client.ignoredUsers.isEmpty) {
      searchUserResults.value = const Left(
        BlockedUsersSearchEmptyState(keyword: ''),
      );
      TwakeDialog.hideLoadingDialog(context);
      return;
    }

    for (final userId in client.ignoredUsers) {
      try {
        final user = await client.getProfileFromUserId(
          userId,
          getFromRooms: false,
        );
        if (!blockedUsers.any((u) => u.userId == user.userId)) {
          blockedUsers.add(user);
        } else {
          blockedUsers.removeWhere((u) => u.userId != user.userId);
        }
      } catch (e) {
        Logs().e(
          "SettingsIgnoreListController::refreshBlockedUsers: Error fetching profile for userId $userId: $e",
        );
      }
    }

    if (blockedUsers.isEmpty) {
      searchUserResults.value = Right(
        BlockedUsersSearchSuccessState(blockedUsers: blockedUsers, keyword: ''),
      );
    } else {
      searchUserResults.value = const Left(
        BlockedUsersSearchEmptyState(keyword: ''),
      );
    }
    TwakeDialog.hideLoadingDialog(context);
  }

  @override
  void initState() {
    listenBlockedUsers();
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    initializeDebouncer((searchTerm) {
      Logs().d("RemovedController::initState: $searchTerm");
      handleSearchResults(searchTerm);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialBlockedUsers();
    });
    super.initState();
  }

  @override
  void dispose() {
    ignoredUsersStreamSub?.cancel();
    textEditingController.dispose();
    inputFocus.dispose();
    searchUserResults.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsBlockedUsersView(this);
}
