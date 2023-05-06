import 'dart:async';

import 'package:dartz/dartz.dart' as dartz;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_contacts_success.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_local_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_network_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contacts_info.dart';
import 'package:fluffychat/pages/contacts/presentation/contacts_picker_view.dart';
import 'package:fluffychat/pages/dialog_creation/dialog_creation.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_presentation_contact_extension.dart';

class ContactsPicker extends StatefulWidget {
  const ContactsPicker({Key? key}) : super(key: key);

  @override
  State<ContactsPicker> createState() => ContactsPickerController();
}

class ContactsPickerController extends State<ContactsPicker> {

  static const debouncerIntervalInMilliseconds = 250;

  late final GetLocalContactsInteractor _getLocalContactsInteractor = GetIt.instance.get<GetLocalContactsInteractor>();
  late final GetNetworkContactsInteractor _getNetworkContactsInteractor = GetIt.instance.get<GetNetworkContactsInteractor>();
  late final Debouncer<String> _debouncer;

  Set<PresentationContact> selectedContacts = {};
  final Map<ContactType, Set<PresentationContact>> _mapCacheContacts = {};

  final StreamController<dartz.Either<Failure, GetContactsSuccess>> localStreamController = StreamController();
  final StreamController<dartz.Either<Failure, GetContactsSuccess>> networkStreamController = StreamController();

  ValueNotifier<bool> haveSelectedContactsNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initializeStreamController();
    _initializeDebouncer();
  }

  void _initializeStreamController() async {
    final futures = [networkStreamController.addStream(_getNetworkContactsInteractor.execute())];
    if (!kIsWeb) {
      futures.add(localStreamController.addStream(_getLocalContactsInteractor.execute()));
    }
    Future.wait(futures);
  }

  void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds), 
      initialValue: '');
    
    _debouncer.values.listen((searchKeyword) async {
      debugPrint(searchKeyword);
      if (!kIsWeb) {
        _fetchLocalContacts(searchKeyword);
      }
      _fetchRemoteContacts(searchKeyword);
    });
  }

  List<PresentationContactsInfo> get presentationContactsList => [
    PresentationContactsInfo(
        title: 'Local Contacts', 
        contactType: ContactType.device,
        contactsStream: localStreamController.stream),
    PresentationContactsInfo(
      title: 'Server Contacts', 
      contactType: ContactType.server,
      contactsStream: networkStreamController.stream)
  ];

  void _fetchLocalContacts(String searchKeyword) {
    _getLocalContactsInteractor
      .execute(cacheContacts: _mapCacheContacts[ContactType.device]?.toContacts(), searchKey: searchKeyword)
      .listen((event) {
        localStreamController.add(event);
      });
  }

  void _fetchRemoteContacts(String searchKeyword) {
    _getNetworkContactsInteractor
        .execute(cacheContacts: _mapCacheContacts[ContactType.server]?.toContacts(), searchKey: searchKeyword)
        .listen((event) {
          networkStreamController.add(event);
        });
  }

  bool isDeviceContactsList(PresentationContactsInfo contacts) {
    return contacts.contactType == ContactType.device;
  }

  void setCacheContacts(Set<PresentationContact> contacts, ContactType contactType) {
    if (contacts.isNotEmpty && _mapCacheContacts[contactType]?.isEmpty != false) {
      _mapCacheContacts[contactType] = contacts;
    }
  } 

  void onSearchBarChanged(String searchKeyword) {
    _debouncer.setValue(searchKeyword);
  }

  void moveToCreateRoomDialog() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => DialogCreation(selectedContacts: selectedContacts,));
  }

  @override
  void dispose() {
    super.dispose();
    localStreamController.close();
    networkStreamController.close();
    _debouncer.cancel();
  }
  
  @override
  Widget build(BuildContext context) => ContactsPickerView(this);
}