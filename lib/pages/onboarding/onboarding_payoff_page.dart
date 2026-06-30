import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/onboarding/steps/onboarding_payoff_step.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Shown right after the first login when contacts permission was granted
/// during onboarding. Runs the address-book sync and reveals the contacts
/// already on Twake (the onboarding payoff), then lands on the chat list.
class OnboardingPayoffPage extends StatefulWidget {
  const OnboardingPayoffPage({super.key});

  @override
  State<OnboardingPayoffPage> createState() => _OnboardingPayoffPageState();
}

class _OnboardingPayoffPageState extends State<OnboardingPayoffPage> {
  final ContactsManager _contactsManager = getIt.get<ContactsManager>();

  final ValueNotifier<bool> _syncStartedNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  void _startSync() {
    final userId = Matrix.of(context).client.userID;
    if (userId == null) {
      _finish();
      return;
    }
    _contactsManager.initialSynchronizeContacts(
      isAvailableSupportPhonebookContacts: true,
      withMxId: userId,
      forceRun: true,
    );
  }

  void _finish() => TwakeApp.router.go('/rooms');

  @override
  void dispose() {
    _syncStartedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().background,
      body: SafeArea(
        child: OnboardingPayoffStep(
          syncStartedNotifier: _syncStartedNotifier,
          phonebookContactsListenable: _phonebookListenable,
          onFinish: _finish,
        ),
      ),
    );
  }

  ValueListenable<Either<Failure, Success>> get _phonebookListenable =>
      _contactsManager.getPhonebookContactsNotifier();
}
