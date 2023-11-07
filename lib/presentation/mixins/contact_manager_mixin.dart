import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success_converter.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_all_contacts_state.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:fluffychat/presentation/converters/presentation_contact_converter.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin class ContactManagerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  final _getAllContactsInteractor = getIt.get<GetAllContactsInteractor>();

  final SuccessConverter converter = PresentationContactConverter();

  final contactsNotifier = ValueNotifier<Either<Failure, Success>>(
    const Right(GetContactsAllInitial()),
  );

  final refreshController = TwakeRefreshController();

  final _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );
  final TextEditingController textEditingController = TextEditingController();

  // FIXME: Consider can use FocusNode instead ?
  final isSearchModeNotifier = ValueNotifier(false);

  final searchFocusNode = FocusNode();

  StreamSubscription? _getContactsSubscription;

  void initSearchContacts({
    SuccessConverter? converter,
  }) {
    contactsNotifier.addListener(() {
      Logs().d('contactsNotifier: ${contactsNotifier.value}');
    });
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) async {
      getAllContacts(keyword: keyword);
    });
    getAllContacts();
  }

  void getAllContacts({String? keyword}) {
    _getContactsSubscription = _getAllContactsInteractor
        .execute(keyword: keyword ?? '', limit: AppConfig.fetchContactsLimit)
        .listen((event) {
      contactsNotifier.value = event.map((success) {
        return converter.convert(success);
      });
      refreshController.refreshCompleted();
    });
  }

  void toggleSearchMode() {
    isSearchModeNotifier.value = !isSearchModeNotifier.value;
    if (isSearchModeNotifier.value) {
      searchFocusNode.requestFocus();
    } else {
      textEditingController.clear();
    }
  }

  void onSelectedContact() {
    searchFocusNode.requestFocus();
    textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textEditingController.text.length,
    );
  }

  void clearSearchBar() {
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
    textEditingController.clear();
  }

  void disposeSearchContacts() {
    _debouncer.cancel();
    textEditingController.dispose();
    isSearchModeNotifier.dispose();
    searchFocusNode.dispose();
    _getContactsSubscription?.cancel();
  }
}
