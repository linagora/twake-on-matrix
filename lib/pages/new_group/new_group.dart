import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/usecase/room/upload_avatar_new_group_chat_interactor.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_info_controller.dart';
import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/pages/settings/settings.dart';
import 'package:fluffychat/utils/platform_infos.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group_view.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup>
  with ComparablePresentationContactMixin {
  final searchContactsController = SearchContactsController();
  final fetchContactsController = FetchContactsController();
  final uploadAvatarNewGroupChatInteractor = getIt.get<UploadAvatarNewGroupChatInteractor>();
  final contactStreamController = StreamController<Either<Failure, GetContactsSuccess>>();
  final groupNameTextEditingController = TextEditingController();
  final uploadAvatarNewGroupChatNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();
  final haveGroupNameNotifier = ValueNotifier(false);

  final int maxFileSizeDefaultInMB = 5 * 1024 * 1024;

  final groupNameFocusNode = FocusNode();
  StreamSubscription? streamSubscription;

  String groupName = "";

  @override
  void initState() {
    super.initState();
    searchContactsController.init();
    onSearchKeywordChanged();
    listenContactsStartList();
    listenSearchContacts();
    listenGroupNameChanged();
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

    selectedContactsMapNotifier.dispose();
    haveGroupNameNotifier.dispose();
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

  void onSearchKeywordChanged() {
    searchContactsController.onSearchKeywordChanged = (String text) {
      if (text.isEmpty) {
        fetchContactsController.fetchCurrentTomContacts();
      } else {
        fetchContactsController.haveMoreCountactsNotifier.value = false;
      }
    };
  }

  Iterable<PresentationContact> get contactsList 
    => selectedContactsMapNotifier.contactsList;

  Set<PresentationContact> getAllContactsGroupChat() {
    final newContactsList = {
      PresentationContact(
        displayName: "You",
        matrixId: Matrix.of(context).client.userID,
      )
    };
    newContactsList.addAll(getSelectedValidContacts(contactsList));
    return newContactsList;
  }

  void moveToNewGroupInfoScreen() async {
    groupNameFocusNode.unfocus();
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
            contactsList: getAllContactsGroupChat(),
            newGroupController: this,
          )
        );
      },
    );
  }

  void uploadAvatarNewGroupChat({
    required Client matrixClient,
    required Uint8List file,
    String? fileName,
    String? contentType,
  }) {
    streamSubscription = uploadAvatarNewGroupChatInteractor.execute(
      matrixClient: matrixClient,
      file: file,
      fileName: fileName,
      contentType: contentType,
    ).listen(
      (event) => _handleUploadAvatarNewGroupChatOnData(context, event),
      onDone: _handleUploadAvatarNewGroupChatOnDone,
      onError: _handleUploadAvatarNewGroupChatOnError
    );
  }

  void _handleUploadAvatarNewGroupChatOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('CreateRoomController::_handleUploadAvatarNewGroupChatOnData() - event: $event');
    uploadAvatarNewGroupChatNotifier.value = event;
  }

  void _handleUploadAvatarNewGroupChatOnDone() {
    Logs().d('CreateRoomController::_handleUploadAvatarNewGroupChatOnDone() - done');
  }

  void _handleUploadAvatarNewGroupChatOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('CreateRoomController::_handleUploadAvatarNewGroupChatOnError() - error: $error | stackTrace: $stackTrace');
  }


  Future<AvatarAction?> _getSaveAvatarActions(BuildContext context) async {
    final actions = [
      if (PlatformInfos.isMobile)
        SheetAction(
          key: AvatarAction.camera,
          label: L10n.of(context)!.openCamera,
          isDefaultAction: true,
          icon: Icons.camera_alt_outlined,
        ),
      SheetAction(
        key: AvatarAction.file,
        label: L10n.of(context)!.openGallery,
        icon: Icons.photo_outlined,
      ),
    ];

    final action = actions.length == 1
        ? actions.single.key
        : await showModalActionSheet<AvatarAction>(
      context: context,
      title: L10n.of(context)!.changeGroupAvatar,
      actions: actions,
    );

    return action;
  }

  void saveAvatarAction(BuildContext context) async {
    final action = await _getSaveAvatarActions(context);
    if (action == null) return;

    MatrixFile file;
    if (PlatformInfos.isMobile) {
      final result = await ImagePicker().pickImage(
        source: action == AvatarAction.camera ? ImageSource.camera : ImageSource
            .gallery,
        imageQuality: 50,
      );
      if (result == null) return;
      file = MatrixFile(
        bytes: await result.readAsBytes(),
        name: result.path,
      );
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final pickedFile = result?.files.firstOrNull;
      if (pickedFile == null) return;
      file = MatrixFile(
        bytes: pickedFile.bytes!,
        name: pickedFile.name,
      );
    }

    uploadAvatarNewGroupChat(
      matrixClient: Matrix.of(context).client,
      file: file.bytes,
      fileName: file.name,
      contentType: file.mimeType,
    );
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
