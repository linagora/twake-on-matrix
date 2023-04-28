import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/lookup_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contacts_info.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_presentation_contact_extension.dart';

import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:get_it/get_it.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({Key? key}) : super(key: key);

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {
  static const debouncerIntervalInMilliseconds = 250;

  late final LookupContactsInteractor _lookupNetworkContactsInteractor = GetIt.instance.get<LookupContactsInteractor>();
  late final FetchContactsInteractor _fetchContactInteractor = GetIt.instance.get<FetchContactsInteractor>();
  late final Debouncer<String> _debouncer;

  final Map<ContactType, Set<PresentationContact>> _mapCacheContacts = {};

  String searchKeyword = "";

  final StreamController<Either<Failure, GetContactsSuccess>> networkStreamController = StreamController();

  @override
  void initState() {
    super.initState();
    _initializeDebouncer();
    _getCurrentContact();
  }
  
   void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds), 
      initialValue: '',
    );
    
    _debouncer.values.listen((searchKeyword) async {
      debugPrint(searchKeyword);
      if (searchKeyword.isEmpty) {
        _getCurrentContact();
      } else {
        _fetchRemoteContacts(searchKeyword);
      }
    });
  }

  void _getCurrentContact() {
    _fetchContactInteractor.execute().listen((event) {
      networkStreamController.add(event);
    });
  }

  void _fetchRemoteContacts(String searchKeyword) {
    _lookupNetworkContactsInteractor
        .execute(cacheContacts: _mapCacheContacts[ContactType.server]?.toContacts(), query: ContactQuery(keyword: searchKeyword))
        .listen((event) {
          networkStreamController.add(event);
        });
  }

  @override
  void dispose() {
    super.dispose();
    networkStreamController.close();
    _debouncer.cancel();
  }

  void onSearchBarChanged(String keyword) {
    _debouncer.setValue(keyword);
    searchKeyword = keyword;
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
