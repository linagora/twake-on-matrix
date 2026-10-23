/// Session-wide "do not show again" choices of the contacts permission
/// prompts (dialog and banner), shared by every screen that lists contacts.
///
/// In memory on purpose: it used to live on `ContactsManager` and was never
/// persisted either, so the prompts come back on the next launch.
class ContactsWarningPreferences {
  bool doNotShowDialogAgain = false;
  bool doNotShowBannerAgain = false;
}

final ContactsWarningPreferences contactsWarningPreferences =
    ContactsWarningPreferences();
