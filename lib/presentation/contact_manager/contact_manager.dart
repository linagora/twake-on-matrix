import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success_converter.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search_contacts_interactor.dart';
import 'package:fluffychat/presentation/converters/presentation_contact_converter.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ContactManager {
  bool _firstSynchronize = false;

  static const _debouncerIntervalInMilliseconds = 300;

  final _getAllContactsInteractor = getIt.get<GetAllContactsInteractor>();

  final searchContactsInteractor = getIt.get<SearchContactsInteractor>();

  final SuccessConverter converter = PresentationContactConverter();

  // FIXME: Consider can use FocusNode instead ?
  final ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);

  final ValueNotifier<Either<Failure, Success>> contactsNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(GetContactsInitial()),
  );

  final ValueNotifier<List<PresentationContact>> tomPresentationContacts =
      ValueNotifier<List<PresentationContact>>([]);

  final ValueNotifier<List<PresentationContact>> phonebookPresentationContacts =
      ValueNotifier<List<PresentationContact>>([]);

  final TwakeRefreshController refreshController = TwakeRefreshController();

  final Debouncer _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );
  final TextEditingController textEditingController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  StreamSubscription? _getContactsSubscription;

  void initSearchContacts({
    SuccessConverter? converter,
  }) {
    contactsNotifier.addListener(() {
      Logs().d(
        'ContactManagerMixin()::initSearchContacts: ${contactsNotifier.value}',
      );
    });
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) async {
      _searchContactsInLocal(keyword: keyword);
    });
    if (!_firstSynchronize) {
      getAllContacts();
      _firstSynchronize = !_firstSynchronize;
    }
  }

  void getAllContacts({String? keyword}) {
    _getContactsSubscription = _getAllContactsInteractor
        .execute(keyword: keyword ?? '', limit: AppConfig.fetchContactsLimit)
        .listen((event) {
      contactsNotifier.value = event.map((success) {
        return converter.convert(success);
      });
      event.fold(
        (_) {},
        (success) {
          if (success is GetContactsSuccess) {
            tomPresentationContacts.value = success.tomContacts
                .expand((e) => e.toPresentationContacts())
                .toList();
            Logs().d(
              "ContactManagerMixin()::getAllContacts(): TomContacts: ${tomPresentationContacts.value.length} "
              "- PhonebookContacts: ${phonebookPresentationContacts.value.length}",
            );
          }
        },
      );
      refreshController.refreshCompleted();
    });
  }

  void _searchContactsInLocal({
    String? keyword,
  }) {
    final tomContacts = tomPresentationContacts.value
        .expand((contact) => contact.toContacts())
        .toList();
    searchContactsInteractor
        .execute(
      keyword: keyword ?? '',
      tomContacts: tomContacts,
    )
        .listen((event) {
      contactsNotifier.value = event.map((success) {
        return converter.convert(success);
      });
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
    tomPresentationContacts.dispose();
    phonebookPresentationContacts.dispose();
    _getContactsSubscription?.cancel();
  }
}
