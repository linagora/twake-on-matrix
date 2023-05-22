import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/data/datasource_impl/contact/tom_contacts_datasource_impl.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/lookup_contacts_interactor.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({Key? key}) : super(key: key);

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {
  static const debouncerIntervalInMilliseconds = 250;

  late final LookupContactsInteractor _lookupNetworkContactsInteractor = GetIt.instance.get<LookupContactsInteractor>();
  late final FetchContactsInteractor _fetchContactsInteractor = GetIt.instance.get<FetchContactsInteractor>();
  late final Debouncer<String> _debouncer;

  String searchKeyword = "";

  final StreamController<Either<Failure, GetContactsSuccess>> networkStreamController = StreamController();

  @override
  void initState() {
    super.initState();
    _initializeDebouncer();
  }
  
   void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds), 
      initialValue: '',
    );
    
    _debouncer.values.listen((searchKeyword) async {
      Logs().d("NewPrivateChatController::_initializeDebouncer: searchKeyword: {searchKeyword}");
      _fetchRemoteContacts(searchKeyword);
    });
  }

  void _fetchRemoteContacts(String searchKeyword) {
    _lookupNetworkContactsInteractor
      .execute(query: ContactQuery(keyword: searchKeyword))
      .listen((event) {
        Logs().d('NewPrivateChatController::_fetchRemoteContacts() - event: $event');
        networkStreamController.add(event);
      });
  }

  void fetchCurrentTomContacts() {
    _fetchContactsInteractor
      .execute()
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
