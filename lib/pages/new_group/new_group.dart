import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/model/room/create_new_group_chat_request.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/presentation/mixin/image_picker_mixin.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:vrouter/vrouter.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup>
  with ComparablePresentationContactMixin, ImagePickerMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final uploadContentInteractor = getIt.get<UploadContentInteractor>();
  final createNewGroupChatInteractor = getIt.get<CreateNewGroupChatInteractor>();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();
  final groupNameTextEditingController = TextEditingController();
  final avatarNotifier = ValueNotifier<AssetEntity?>(null);
  final createRoomStateNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  final haveGroupNameNotifier = ValueNotifier(false);
  final groupNameFocusNode = FocusNode();
  StreamSubscription? uploadContentInteractorStreamSubscription;
  StreamSubscription? createNewGroupChatInteractorStreamSubscription;

  String groupName = "";

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    listenContactsStartList();
    listenSearchContacts();
    listenGroupNameChanged();
    _registerListenerForSelectedImagesChanged();
    fetchContactsController.fetchCurrentTomContacts();
    fetchContactsController.listenForScrollChanged(fetchContactsController: fetchContactsController);
    searchContactsController.onSearchKeywordChanged = (searchKey) {
      disableLoadMoreInSearch();
    };
  }

  void disableLoadMoreInSearch() {
    fetchContactsController.allowLoadMore = searchContactsController.searchKeyword.isEmpty;
  }

  @override
  void dispose() {
    super.dispose();
    contactStreamController.close();
    searchContactsController.dispose();
    fetchContactsController.dispose();
    groupNameTextEditingController.dispose();
    imagePickerController.dispose();
    selectedContactsMapNotifier.dispose();
    haveGroupNameNotifier.dispose();
    avatarNotifier.dispose();
    uploadContentInteractorStreamSubscription?.cancel();
    createNewGroupChatInteractorStreamSubscription?.cancel();
  }

  void listenContactsStartList() {
    fetchContactsController.streamController.stream.listen((event) {
      Logs().d('NewGroupController::fetchContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void listenSearchContacts() {
    searchContactsController.lookupStreamController.stream.listen((event) {
      Logs().d('NewGroupController::_fetchRemoteContacts() - event: $event');
      contactStreamController.add(event);
    });
  }

  void onCloseSearchTapped() {
    searchContactsController.onCloseSearchTapped();
    fetchContactsController.haveMoreCountactsNotifier.value = false;
  }

  void selectedContact() {
    searchContactsController.onSelectedContact();
  }


  Future<ServerConfig> getServerConfig() async {
    final serverConfig = await Matrix.of(context).client.getConfig();
    return serverConfig;
  }

  Iterable<PresentationContact> get contactsList 
    => selectedContactsMapNotifier.contactsList;

  Future<Set<PresentationContact>> getAllContactsGroupChat({bool isCustomDisplayName = true}) async {
    final userId = Matrix.of(context).client.userID;
    final profile = await Matrix.of(context).client.getProfileFromUserId(userId!);
    final newContactsList = {
      PresentationContact(
        displayName: isCustomDisplayName ? L10n.of(context)!.you : profile.displayName,
        matrixId: Matrix.of(context).client.userID,
      )
    };
    newContactsList.addAll(getSelectedValidContacts(contactsList));
    return newContactsList;
  }

  void _getDefaultGroupName(Set<PresentationContact> contactLis) async {
    if (contactLis.length <= 3) {
      final groupName = contactLis.map((contact) => contact.displayName).join(", ");
      groupNameTextEditingController.text = groupName;
      groupNameTextEditingController.selection = TextSelection.fromPosition(
          TextPosition(offset: groupNameTextEditingController.text.length)
      );
      groupNameFocusNode.requestFocus();
    } else {
      groupNameTextEditingController.clear();
    }
  }

  void moveToNewGroupInfoScreen() async {
    final contactList = await getAllContactsGroupChat(isCustomDisplayName: false);
    _getDefaultGroupName(contactList);
    await showGeneralDialog(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.white,
      transitionBuilder: (context, animation1, animation2, widget) {
        return AppRoutes.rightToLeftTransition(
          animation1,
          animation2,
          NewGroupChatInfo(
            contactsList: contactList,
            newGroupController: this,
          )
        );
      },
    );
  }

  void createNewGroup({ required String? uriAvatar }) {
    final client = Matrix.of(context).client;
    createNewGroupChatAction(
      matrixClient: client,
      createNewGroupChatRequest: CreateNewGroupChatRequest(
        groupName: groupName,
        invite: getSelectedValidContacts(contactsList)
            .map<String>((contact) => contact.matrixId!)
            .toList(),
        enableEncryption: true,
        urlAvatar: uriAvatar
      ),
    );
  }

  void uploadAvatarNewGroupChat({
    required Client matrixClient,
    required AssetEntity entity,
  }) {
    uploadContentInteractorStreamSubscription = uploadContentInteractor.execute(
      matrixClient: matrixClient,
      entity: entity,
    ).listen(
      (event) => _handleUploadAvatarNewGroupChatOnData(context, event),
      onDone: _handleUploadAvatarNewGroupChatOnDone,
      onError: _handleUploadAvatarNewGroupChatOnError
    );
  }

  void createNewGroupChatAction({
    required Client matrixClient,
    required CreateNewGroupChatRequest createNewGroupChatRequest,
  }) {
    createNewGroupChatInteractorStreamSubscription = createNewGroupChatInteractor.execute(
      matrixClient: matrixClient,
      createNewGroupChatRequest: createNewGroupChatRequest,
    ).listen(
      (event) => _handleCreateNewGroupChatChatOnData(context, event),
      onDone: _handleCreateNewGroupChatOnDone,
      onError: _handleCreateNewGroupChatOnError
    );
  }

  void _handleUploadAvatarNewGroupChatOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnData()');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnData() - failure: $failure');
      },
      (success) {
        Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnData() - success: $success');
        if (success is UploadContentSuccess) {
          final uriAvatar = success.uri.toString();
          createNewGroup(uriAvatar: uriAvatar);
        }
      },
    );
  }

  void _handleUploadAvatarNewGroupChatOnDone() {
    Logs().d('NewGroupController::_handleUploadAvatarNewGroupChatOnDone() - done');
  }

  void _handleUploadAvatarNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace');
  }

  void _handleCreateNewGroupChatChatOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('NewGroupController::_handleCreateNewGroupChatChatOnData()');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('NewGroupController::_handleCreateNewGroupChatChatOnData() - failure: $failure');
      },
      (success) {
        Logs().d('NewGroupController::_handleCreateNewGroupChatChatOnData() - success: $success');
        if (success is CreateNewGroupChatSuccess) {
          removeAllImageSelected();
          _goToRoom(context, success.roomId);
        }
      },
    );
  }

  void _handleCreateNewGroupChatOnDone() {
    Logs().d('NewGroupController::_handleCreateNewGroupChatOnDone() - done');
  }

  void _handleCreateNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('NewGroupController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace');
  }

  void _goToRoom(BuildContext context, String roomId) {
    VRouter.of(context).toSegments(['rooms', roomId]);
  }

  void _registerListenerForSelectedImagesChanged() {
    imagePickerController.addListener(() {
      numberSelectedImagesNotifier.value = imagePickerController.selectedAssets.length;
    });

    numberSelectedImagesNotifier.addListener(() {
      if (numberSelectedImagesNotifier.value == 1) {
        Navigator.pop(context);
        avatarNotifier.value = imagePickerController.selectedAssets.first.asset;
        removeAllImageSelected();
      }
    });
  }

  void showImagesPickerAction({
    required BuildContext context,
  }) async {
    final isLoading = createRoomStateNotifier.value?.fold(
      (l) => false, 
      (r) => r is UploadContentLoading || r is CreateNewGroupChatLoading
    );
    if (isLoading == true) {
      // Disable if already uploading
      return;
    }
    final currentPermissionPhotos = await getCurrentPhotoPermission();
    final currentPermissionCamera = await getCurrentCameraPermission();
    if (currentPermissionPhotos != null && currentPermissionCamera != null) {
      showImagesPickerBottomSheet(
        context: context,
        permissionStatusPhotos: currentPermissionPhotos,
        permissionStatusCamera: currentPermissionCamera,
        onItemAction: (_) {},
      );
    }
  }


  @override
  void removeAllImageSelected() {
    uploadContentInteractorStreamSubscription?.cancel();
    imagePickerController.clearAssetCounter();
    numberSelectedImagesNotifier.value = 0;
    Logs().d('NewGroupController::_removeAllImageSelected() - numberSelectedImagesNotifier.value  ${numberSelectedImagesNotifier.value}');
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
