// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class L10nPl extends L10n {
  L10nPl([String locale = 'pl']) : super(locale);

  @override
  String get passwordsDoNotMatch => 'Hasła nie pasują!';

  @override
  String get pleaseEnterValidEmail => 'Proszę podaj poprawny adres email.';

  @override
  String get repeatPassword => 'Powtórz hasło';

  @override
  String pleaseChooseAtLeastChars(Object min) {
    return 'Proszę podaj przynajmniej $min znaków.';
  }

  @override
  String get about => 'O nas';

  @override
  String get updateAvailable => 'Twake Chat update available';

  @override
  String get updateNow => 'Start update in background';

  @override
  String get accept => 'Akceptuj';

  @override
  String acceptedTheInvitation(Object username) {
    return '$username zaakceptował/-a zaproszenie';
  }

  @override
  String get account => 'Konto';

  @override
  String activatedEndToEndEncryption(Object username) {
    return '$username aktywował/-a szyfrowanie end-to-end';
  }

  @override
  String get addEmail => 'Dodaj adres email';

  @override
  String get confirmMatrixId =>
      'Please confirm your Matrix ID in order to delete your account.';

  @override
  String supposedMxid(Object mxid) {
    return 'This should be $mxid';
  }

  @override
  String get addGroupDescription => 'Dodaj opis grupy';

  @override
  String get addToSpace => 'Dodaj do przestrzeni';

  @override
  String get admin => 'Admin';

  @override
  String get alias => 'alias';

  @override
  String get all => 'Wszystkie';

  @override
  String get allChats => 'Wszystkie';

  @override
  String get commandHint_googly => 'Send some googly eyes';

  @override
  String get commandHint_cuddle => 'Send a cuddle';

  @override
  String get commandHint_hug => 'Send a hug';

  @override
  String googlyEyesContent(Object senderName) {
    return '$senderName sends you googly eyes';
  }

  @override
  String cuddleContent(Object senderName) {
    return '$senderName cuddles you';
  }

  @override
  String hugContent(Object senderName) {
    return '$senderName hugs you';
  }

  @override
  String answeredTheCall(Object senderName, Object sendername) {
    return '$senderName odebrał połączenie';
  }

  @override
  String get anyoneCanJoin => 'Każdy może dołączyć';

  @override
  String get appLock => 'Blokada aplikacji';

  @override
  String get archive => 'Archiwum';

  @override
  String get archivedRoom => 'Zarchiwizowane pokoje';

  @override
  String get areGuestsAllowedToJoin => 'Czy użytkownicy-goście mogą dołączyć';

  @override
  String get areYouSure => 'Jesteś pewny/-a?';

  @override
  String get areYouSureYouWantToLogout => 'Czy napewno chcesz się wylogować?';

  @override
  String get askSSSSSign =>
      'Aby zalogować inną osobę, proszę wpisać hasło przechowywania lub klucz odzyskiwania.';

  @override
  String askVerificationRequest(Object username) {
    return 'Zaakceptować tą prośbę weryfikacji od $username?';
  }

  @override
  String get autoplayImages =>
      'Automatycznie odtwarzaj animowane naklejki i emotki';

  @override
  String badServerLoginTypesException(Object serverVersions,
      Object supportedVersions, Object suportedVersions) {
    return 'Serwer wspiera typy logowania:\n$serverVersions\nAle ta aplikacja wpiera tylko:\n$supportedVersions';
  }

  @override
  String get sendOnEnter => 'Wyślij enterem';

  @override
  String badServerVersionsException(Object serverVersions,
      Object supportedVersions, Object serverVerions, Object suportedVersions) {
    return 'Serwer wspiera wersje Spec:\n$serverVersions\nAle aplikacja wspiera tylko $supportedVersions';
  }

  @override
  String get banFromChat => 'Ban na czacie';

  @override
  String get banned => 'Zbanowany/-a';

  @override
  String bannedUser(Object username, Object targetName) {
    return '$username zbanował/-a $targetName';
  }

  @override
  String get blockDevice => 'Zablokuj Urządzenie';

  @override
  String get blocked => 'Zablokowane';

  @override
  String get botMessages => 'Wiadomości Botów';

  @override
  String get bubbleSize => 'Rozmiar bąbelków';

  @override
  String get cancel => 'Anuluj';

  @override
  String cantOpenUri(Object uri) {
    return 'Nie można otworzyć linku $uri';
  }

  @override
  String get changeDeviceName => 'Zmień nazwę urządzenia';

  @override
  String changedTheChatAvatar(Object username) {
    return '$username zmienił/-a zdjęcie profilowe';
  }

  @override
  String changedTheChatDescriptionTo(Object username, Object description) {
    return '$username zmienił/-a opis czatu na: \'$description\'';
  }

  @override
  String changedTheChatNameTo(Object username, Object chatname) {
    return '$username zmienił/-a nick na: \'$chatname\'';
  }

  @override
  String changedTheChatPermissions(Object username) {
    return '$username zmienił/-a uprawnienia czatu';
  }

  @override
  String changedTheDisplaynameTo(Object username, Object displayname) {
    return '$username zmienił/-a wyświetlany nick na: $displayname';
  }

  @override
  String changedTheGuestAccessRules(Object username) {
    return '$username zmienił/-a zasady dostępu dla gości';
  }

  @override
  String changedTheGuestAccessRulesTo(Object username, Object rules) {
    return '$username zmienił/-a zasady dostępu dla gości na: $rules';
  }

  @override
  String changedTheHistoryVisibility(Object username) {
    return '$username zmienił/-a widoczność historii';
  }

  @override
  String changedTheHistoryVisibilityTo(Object username, Object rules) {
    return '$username zmienił/-a widoczność historii na: $rules';
  }

  @override
  String changedTheJoinRules(Object username) {
    return '$username zmienił/-a zasady wejścia';
  }

  @override
  String changedTheJoinRulesTo(Object username, Object joinRules) {
    return '$username zmienił/-a zasady wejścia na: $joinRules';
  }

  @override
  String changedTheProfileAvatar(Object username) {
    return '$username zmienił/-a zdjęcie profilowe';
  }

  @override
  String changedTheRoomAliases(Object username) {
    return '$username zmienił/-a skrót pokoju';
  }

  @override
  String changedTheRoomInvitationLink(Object username) {
    return '$username zmienił/-a link do zaproszenia do pokoju';
  }

  @override
  String get changePassword => 'Zmień hasło';

  @override
  String get changeTheHomeserver => 'Zmień serwer domyślny';

  @override
  String get changeTheme => 'Zmień swój styl';

  @override
  String get changeTheNameOfTheGroup => 'Zmień nazwę grupy';

  @override
  String get changeWallpaper => 'Zmień tapetę';

  @override
  String get changeYourAvatar => 'Zmień avatar';

  @override
  String get channelCorruptedDecryptError => 'Szyfrowanie zostało uszkodzone';

  @override
  String get chat => 'Rozmowa';

  @override
  String get yourUserId => 'Twoja nazwa użytkownika:';

  @override
  String get yourChatBackupHasBeenSetUp =>
      'Twoja kopia zapasowa chatu została ustawiona.';

  @override
  String get chatBackup => 'Kopia zapasowa Rozmów';

  @override
  String get chatBackupDescription =>
      'Twoja kopia zapasowa Rozmów jest zabezpieczona kluczem bezpieczeństwa. Uważaj żeby go nie zgubić.';

  @override
  String get chatDetails => 'Szczegóły czatu';

  @override
  String get chatHasBeenAddedToThisSpace =>
      'Chat został dodany do tej przestrzeni';

  @override
  String get chats => 'Rozmowy';

  @override
  String get chooseAStrongPassword => 'Wybierz silne hasło';

  @override
  String get chooseAUsername => 'Wybierz nick';

  @override
  String get clearArchive => 'Wyczyść archiwum';

  @override
  String get close => 'Zamknij';

  @override
  String get commandHint_markasdm => 'Mark as direct chat';

  @override
  String get commandHint_markasgroup => 'Mark as chat';

  @override
  String get commandHint_ban => 'Zablokuj użytkownika w tym pokoju';

  @override
  String get commandHint_clearcache => 'Wyczyść pamięć podręczną';

  @override
  String get commandHint_create =>
      'Stwórz pusty chat\nUżyj --no-encryption by wyłączyć szyfrowanie';

  @override
  String get commandHint_discardsession => 'Discard session';

  @override
  String get commandHint_dm =>
      'Rozpocznij bezpośredni chat\nUżyj --no-encryption by wyłączyć szyfrowanie';

  @override
  String get commandHint_html => 'Wyślij tekst sformatowany w HTML';

  @override
  String get commandHint_invite => 'Zaproś użytkownika do pokoju';

  @override
  String get commandHint_join => 'Dołącz do podanego pokoju';

  @override
  String get commandHint_kick => 'Usuń tego użytkownika z tego pokoju';

  @override
  String get commandHint_leave => 'Wyjdź z tego pokoju';

  @override
  String get commandHint_me => 'Opisz siebie';

  @override
  String get commandHint_myroomavatar =>
      'Ustaw awatar dla tego pokoju (przez mxc-uri)';

  @override
  String get commandHint_myroomnick =>
      'Ustaw nazwę wyświetlaną dla tego pokoju';

  @override
  String get commandHint_op =>
      'Ustaw moc uprawnień użytkownika (domyślnie: 50)';

  @override
  String get commandHint_plain => 'Wyślij niesformatowany tekst';

  @override
  String get commandHint_react => 'Wyślij odpowiedź jako reakcję';

  @override
  String get commandHint_send => 'Wyślij wiadomość';

  @override
  String get commandHint_unban => 'Odblokuj użytkownika w tym pokoju';

  @override
  String get commandInvalid => 'Nieprawidłowe polecenie';

  @override
  String commandMissing(Object command) {
    return '$command nie jest poleceniem.';
  }

  @override
  String get compareEmojiMatch =>
      'Porównaj i sprawdź czy na innym urządzeniu wyświetlają się te same emoji:';

  @override
  String get compareNumbersMatch =>
      'Porównaj i sprawdź czy na innym urządzeniu wyświetlają się te same cyfry:';

  @override
  String get configureChat => 'Konfiguruj chat';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get connect => 'Połącz';

  @override
  String get contactHasBeenInvitedToTheGroup =>
      'Kontakt został zaproszony do grupy';

  @override
  String get containsDisplayName => 'Posiada wyświetlaną nazwę';

  @override
  String get containsUserName => 'Posiada nazwę użytkownika';

  @override
  String get contentHasBeenReported =>
      'Zawartość została zgłoszona administratorom serwera';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copyToClipboard => 'Skopiuj do schowka';

  @override
  String couldNotDecryptMessage(Object error) {
    return 'Nie można odszyfrować wiadomości: $error';
  }

  @override
  String countMembers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'no members',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Stwórz';

  @override
  String createdTheChat(Object username) {
    return '$username stworzył/-a czat';
  }

  @override
  String get createNewGroup => 'Stwórz nową grupę';

  @override
  String get createNewSpace => 'Nowa przestrzeń';

  @override
  String get crossSigningEnabled => 'Cross-signing on';

  @override
  String get currentlyActive => 'Obecnie aktywny/-a';

  @override
  String get darkTheme => 'Ciemny';

  @override
  String dateAndTimeOfDay(Object date, Object timeOfDay) {
    return '$date, $timeOfDay';
  }

  @override
  String dateWithoutYear(Object month, Object day) {
    return '$month-$day';
  }

  @override
  String dateWithYear(Object year, Object month, Object day) {
    return '$day-$month-$year';
  }

  @override
  String get deactivateAccountWarning =>
      'To dezaktywuje twoje konto. To jest nieodwracalne ! Czy jesteś pewien?';

  @override
  String get defaultPermissionLevel => 'Domyślny poziom uprawnień';

  @override
  String get delete => 'Usuń';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get deny => 'Odrzuć';

  @override
  String get device => 'Urządzenie';

  @override
  String get deviceId => 'ID Urządzenia';

  @override
  String get devices => 'Urządzenia';

  @override
  String get directChats => 'Rozmowy bezpośrednie';

  @override
  String get discover => 'Odkrywaj';

  @override
  String get displaynameHasBeenChanged => 'Wyświetlany nick został zmieniony';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Edytuj';

  @override
  String get editBlockedServers => 'Edytuj blokowane serwery';

  @override
  String get editChatPermissions => 'Edytuj uprawnienia';

  @override
  String get editDisplayname => 'Edytuj wyświetlany nick';

  @override
  String get editRoomAliases => 'Zmień aliasy pokoju';

  @override
  String get editRoomAvatar => 'Edytuj zdjęcie pokoju';

  @override
  String get emoteExists => 'Emotikon już istnieje!';

  @override
  String get emoteInvalid => 'Nieprawidłowy kod emotikony!';

  @override
  String get emotePacks => 'Paczki emotikon dla pokoju';

  @override
  String get emoteSettings => 'Ustawienia Emotikon';

  @override
  String get emoteShortcode => 'Kod Emotikony';

  @override
  String get emoteWarnNeedToPick => 'Musisz wybrać kod emotikony oraz obraz!';

  @override
  String get emptyChat => 'Pusty czat';

  @override
  String get enableEmotesGlobally => 'Włącz paczkę emotikon globalnie';

  @override
  String get enableEncryption => 'Aktywuj szyfowanie';

  @override
  String get enableEncryptionWarning =>
      'Nie będziesz już mógł wyłączyć szyfrowania. Jesteś pewny?';

  @override
  String get encrypted => 'Szyfrowane';

  @override
  String get encryption => 'Szyfrowanie';

  @override
  String get encryptionNotEnabled => 'Szyfrowanie nie jest włączone';

  @override
  String endedTheCall(Object senderName) {
    return '$senderName zakończył połączenie';
  }

  @override
  String get enterGroupName => 'Enter chat name';

  @override
  String get enterAnEmailAddress => 'Wpisz adres email';

  @override
  String get enterASpacepName => 'Podaj nazwę przestrzeni';

  @override
  String get homeserver => 'Adres serwera';

  @override
  String get enterYourHomeserver => 'Wpisz swój serwer domowy';

  @override
  String errorObtainingLocation(Object error) {
    return 'Error obtaining location: $error';
  }

  @override
  String get everythingReady => 'Wszystko gotowe!';

  @override
  String get extremeOffensive => 'Extremely offensive';

  @override
  String get fileName => 'Nazwa pliku';

  @override
  String get fluffychat => 'FluffyChat';

  @override
  String get fontSize => 'Rozmiar czcionki';

  @override
  String get forward => 'Przekaż';

  @override
  String get friday => 'Piątek';

  @override
  String get fromJoining => 'Od dołączenia';

  @override
  String get fromTheInvitation => 'Od zaproszenia';

  @override
  String get goToTheNewRoom => 'Przejdź do nowego pokoju';

  @override
  String get group => 'Grupa';

  @override
  String get groupDescription => 'Opis grupy';

  @override
  String get groupDescriptionHasBeenChanged => 'Opis grupy został zmieniony';

  @override
  String get groupIsPublic => 'Grupa jest publiczna';

  @override
  String get groups => 'Grupy';

  @override
  String groupWith(Object displayname) {
    return 'Grupa z $displayname';
  }

  @override
  String get guestsAreForbidden => 'Goście są zabronieni';

  @override
  String get guestsCanJoin => 'Goście mogą dołączyć';

  @override
  String hasWithdrawnTheInvitationFor(Object username, Object targetName) {
    return '$username wycofał/-a zaproszenie dla $targetName';
  }

  @override
  String get help => 'Pomoc';

  @override
  String get hideRedactedEvents => 'Ukryj informacje o zredagowaniu';

  @override
  String get hideUnknownEvents => 'Ukryj nieznane wdarzenia';

  @override
  String get howOffensiveIsThisContent => 'How offensive is this content?';

  @override
  String get id => 'ID';

  @override
  String get identity => 'Tożsamość';

  @override
  String get ignore => 'Ignoruj';

  @override
  String get ignoredUsers => 'Ignorowani użytkownicy';

  @override
  String get ignoreListDescription =>
      'Możesz ignorować użytkowników którzy cię irytują. Nie będziesz odbierać od nich wiadomości ani żadnych zaproszeń od użytkowników na tej liście.';

  @override
  String get ignoreUsername => 'Ignoruj użytkownika';

  @override
  String get iHaveClickedOnLink => 'Nacisnąłem na link';

  @override
  String get incorrectPassphraseOrKey =>
      'Złe hasło bezpieczeństwa lub klucz odzyskiwania';

  @override
  String get inoffensive => 'Inoffensive';

  @override
  String get inviteContact => 'Zaproś kontakty';

  @override
  String inviteContactToGroup(Object groupName) {
    return 'Zaproś kontakty do $groupName';
  }

  @override
  String get invited => 'Zaproszono';

  @override
  String invitedUser(Object username, Object targetName) {
    return '$username zaprosił/-a $targetName';
  }

  @override
  String get invitedUsersOnly => 'Tylko zaproszeni użytkownicy';

  @override
  String get inviteForMe => 'Zaproszenie dla mnie';

  @override
  String inviteText(Object username, Object link) {
    return '$username zaprosił/-a cię do FluffyChat. \n1. Zainstaluj FluffyChat: https://fluffychat.im \n2. Zarejestuj się lub zaloguj \n3. Otwórz link zaproszenia: $link';
  }

  @override
  String get isTyping => 'pisze';

  @override
  String joinedTheChat(Object username) {
    return '$username dołączył/-a do czatu';
  }

  @override
  String get joinRoom => 'Dołącz do pokoju';

  @override
  String get keysCached => 'Klucze są załadowane';

  @override
  String kicked(Object username, Object targetName) {
    return '$username wyrzucił/-a $targetName';
  }

  @override
  String kickedAndBanned(Object username, Object targetName) {
    return '$username wyrzucił/-a i zbanował/-a $targetName';
  }

  @override
  String get kickFromChat => 'Wyrzuć z czatu';

  @override
  String lastActiveAgo(Object localizedTimeShort) {
    return 'Ostatnio widziano: $localizedTimeShort';
  }

  @override
  String get lastSeenLongTimeAgo => 'Widziany/-a dawno temu';

  @override
  String get leave => 'Opuść';

  @override
  String get leftTheChat => 'Opuścił/-a czat';

  @override
  String get license => 'Licencja';

  @override
  String get lightTheme => 'Jasny';

  @override
  String loadCountMoreParticipants(Object count) {
    return 'Załaduj jeszcze $count uczestników';
  }

  @override
  String get dehydrate => 'Export session and wipe device';

  @override
  String get dehydrateWarning =>
      'This action cannot be undone. Ensure you safely store the backup file.';

  @override
  String get dehydrateShare =>
      'This is your private FluffyChat export. Ensure you don\'t lose it and keep it private.';

  @override
  String get dehydrateTor => 'TOR Users: Export session';

  @override
  String get dehydrateTorLong =>
      'For TOR users, it is recommended to export the session before closing the window.';

  @override
  String get hydrateTor => 'TOR Users: Import session export';

  @override
  String get hydrateTorLong =>
      'Did you export your session last time on TOR? Quickly import it and continue chatting.';

  @override
  String get hydrate => 'Restore from backup file';

  @override
  String get loadingPleaseWait => 'Ładowanie… Proszę czekać.';

  @override
  String get loadingStatus => 'Loading status...';

  @override
  String get loadMore => 'Załaduj więcej…';

  @override
  String get locationDisabledNotice =>
      'Usługi lokalizacji są wyłączone. Proszę włącz je aby móc udostępnić swoją lokalizację.';

  @override
  String get locationPermissionDeniedNotice =>
      'Brak uprawnień. Proszę zezwól aplikacji na dostęp do lokalizacji aby móc ją udostępnić.';

  @override
  String get login => 'Zaloguj';

  @override
  String logInTo(Object homeserver) {
    return 'Zaloguj się do $homeserver';
  }

  @override
  String get loginWithOneClick => 'Zaloguj się jednym kliknięciem';

  @override
  String get logout => 'Wyloguj';

  @override
  String get makeSureTheIdentifierIsValid =>
      'Upewnij się, że identyfikator jest prawidłowy';

  @override
  String get memberChanges => 'Zmiany członków';

  @override
  String get mention => 'Wzmianka';

  @override
  String get messages => 'Wiadomości';

  @override
  String get messageWillBeRemovedWarning =>
      'Wiadomość zostanie usunięta dla wszystkich użytkowników';

  @override
  String get noSearchResult => 'No matching search results.';

  @override
  String get moderator => 'Moderator';

  @override
  String get monday => 'Poniedziałek';

  @override
  String get muteChat => 'Wycisz czat';

  @override
  String get needPantalaimonWarning =>
      'Należy pamiętać, że Pantalaimon wymaga na razie szyfrowania end-to-end.';

  @override
  String get newChat => 'Nowa rozmowa';

  @override
  String get newMessageInTwake => 'You have 1 encrypted message';

  @override
  String get newVerificationRequest => 'Nowa prośba o weryfikację!';

  @override
  String get noMoreResult => 'No more result!';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Dalej';

  @override
  String get no => 'Nie';

  @override
  String get noConnectionToTheServer => 'Brak połączenia z serwerem';

  @override
  String get noEmotesFound => 'No emotes found. 😕';

  @override
  String get noEncryptionForPublicRooms =>
      'Możesz aktywować szyfrowanie dopiero kiedy pokój nie będzie publicznie dostępny.';

  @override
  String get noGoogleServicesWarning =>
      'Wygląda na to, że nie masz usług Google w swoim telefonie. To dobra decyzja dla twojej prywatności! Aby otrzymywać powiadomienia wysyłane w FluffyChat, zalecamy korzystanie z https://microg.org/ lub https://unifiedpush.org/.';

  @override
  String noMatrixServer(Object server1, Object server2) {
    return '$server1 is no matrix server, use $server2 instead?';
  }

  @override
  String get shareYourInviteLink => 'Share your invite link';

  @override
  String get typeInInviteLinkManually => 'Wpisz link ręcznie...';

  @override
  String get scanQrCode => 'Skanuj kod QR';

  @override
  String get none => 'Brak';

  @override
  String get noPasswordRecoveryDescription =>
      'Nie dodałeś jeszcze sposobu aby odzyskać swoje hasło.';

  @override
  String get noPermission => 'Brak uprawnień';

  @override
  String get noRoomsFound => 'Nie znaleziono pokoi…';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String numUsersTyping(Object count) {
    return '$count users are typing';
  }

  @override
  String get obtainingLocation => 'Uzyskiwanie lokalizacji…';

  @override
  String get offensive => 'Agresywne';

  @override
  String get offline => 'Offline';

  @override
  String get aWhileAgo => 'a while ago';

  @override
  String get ok => 'Ok';

  @override
  String get online => 'Online';

  @override
  String get onlineKeyBackupEnabled => 'Online Key Backup is enabled';

  @override
  String get cannotEnableKeyBackup =>
      'Cannot enable Chat Backup. Please Go to Settings to try it again.';

  @override
  String get cannotUploadKey => 'Cannot store Key Backup.';

  @override
  String get oopsPushError =>
      'Ups! Wystąpił błąd podczas ustawiania powiadomień push.';

  @override
  String get oopsSomethingWentWrong => 'Ups! Coś poszło nie tak…';

  @override
  String get openAppToReadMessages => 'Otwórz aplikację by odczytać wiadomości';

  @override
  String get openCamera => 'Otwórz aparat';

  @override
  String get openVideoCamera => 'Nagraj film';

  @override
  String get oneClientLoggedOut => 'Jedno z twoich urządzeń zostało wylogowane';

  @override
  String get addAccount => 'Dodaj konto';

  @override
  String get editBundlesForAccount => 'Edit bundles for this account';

  @override
  String get addToBundle => 'Add to bundle';

  @override
  String get removeFromBundle => 'Remove from this bundle';

  @override
  String get bundleName => 'Bundle name';

  @override
  String get enableMultiAccounts =>
      '(BETA) Włącza obsługę wiele kont na tym urządzeniu';

  @override
  String get openInMaps => 'Otwórz w mapach';

  @override
  String get link => 'Link';

  @override
  String get serverRequiresEmail =>
      'Ten serwer wymaga potwierdzenia twojego adresu email w celu rejestracji.';

  @override
  String get optionalGroupName => '(Opcjonalnie) Nazwa grupy';

  @override
  String get or => 'Lub';

  @override
  String get participant => 'Uczestnik';

  @override
  String get passphraseOrKey => 'passphrase or recovery key';

  @override
  String get password => 'Hasło';

  @override
  String get passwordForgotten => 'Zapomniano hasła';

  @override
  String get passwordHasBeenChanged => 'Hasło zostało zmienione';

  @override
  String get passwordRecovery => 'Odzyskiwanie hasła';

  @override
  String get people => 'Osoby';

  @override
  String get pickImage => 'Wybierz obraz';

  @override
  String get pin => 'Przypnij';

  @override
  String play(Object fileName) {
    return 'Otwórz $fileName';
  }

  @override
  String get pleaseChoose => 'Proszę wybierz';

  @override
  String get pleaseChooseAPasscode => 'Please choose a pass code';

  @override
  String get pleaseChooseAUsername => 'Wybierz nick';

  @override
  String get pleaseClickOnLink =>
      'Proszę kliknij w odnośnik wysłany na email aby kontynuować.';

  @override
  String get pleaseEnter4Digits =>
      'Proszę podaj 4 cyfry. By wyłączyć blokadę pozostaw puste.';

  @override
  String get pleaseEnterAMatrixIdentifier =>
      'Wprowadź proszę identyfikator matrix.';

  @override
  String get pleaseEnterRecoveryKey => 'Please enter your recovery key:';

  @override
  String get pleaseEnterYourPassword => 'Wpisz swoje hasło';

  @override
  String get pleaseEnterYourPin => 'Proszę podaj pin';

  @override
  String get pleaseEnterYourUsername => 'Wpisz swój nick';

  @override
  String get pleaseFollowInstructionsOnWeb =>
      'Wykonaj instrukcje na stronie internetowej i naciśnij dalej.';

  @override
  String get privacy => 'Prywatność';

  @override
  String get publicRooms => 'Publiczne pokoje';

  @override
  String get pushRules => 'Zasady push';

  @override
  String get reason => 'Powód';

  @override
  String get recording => 'Nagranie';

  @override
  String redactedAnEvent(Object username) {
    return '$username stworzył/-a wydarzenie';
  }

  @override
  String get redactMessage => 'Przekaż wiadomość';

  @override
  String get register => 'Zarejestruj';

  @override
  String get reject => 'Odrzuć';

  @override
  String rejectedTheInvitation(Object username) {
    return '$username odrzucił/-a zaproszenie';
  }

  @override
  String get rejoin => 'Dołącz ponownie';

  @override
  String get remove => 'Usuń';

  @override
  String get removeAllOtherDevices => 'Usuń wszystkie inne urządzenia';

  @override
  String removedBy(Object username) {
    return 'Usunięta przez $username';
  }

  @override
  String get removeDevice => 'Usuń urządzenie';

  @override
  String get unbanFromChat => 'Usuń blokadę';

  @override
  String get removeYourAvatar => 'Usuń swój avatar';

  @override
  String get renderRichContent =>
      'Pokazuj w wiadomościach pogrubienia i podkreślenia';

  @override
  String get replaceRoomWithNewerVersion => 'Zamień pokój na nową wersję';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get reportMessage => 'Zgłoś wiadomość';

  @override
  String get requestPermission => 'Prośba o pozwolenie';

  @override
  String get roomHasBeenUpgraded => 'Pokój zostać zaktualizowany';

  @override
  String get roomVersion => 'Wersja pokoju';

  @override
  String get saturday => 'Sobota';

  @override
  String get saveFile => 'Zapisz plik';

  @override
  String get searchForPeopleAndChannels => 'Search for people and channels';

  @override
  String get security => 'Bezpieczeństwo';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyLost => 'Recovery key lost?';

  @override
  String seenByUser(Object username) {
    return 'Zobaczone przez $username';
  }

  @override
  String seenByUserAndCountOthers(Object username, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobaczone przez $username oraz $count innych',
    );
    return '$_temp0';
  }

  @override
  String seenByUserAndUser(Object username, Object username2) {
    return 'Zobaczone przez $username oraz $username2';
  }

  @override
  String get send => 'Wyślij';

  @override
  String get sendAMessage => 'Wyślij wiadomość';

  @override
  String get sendAsText => 'Wyślij jako tekst';

  @override
  String get sendAudio => 'Wyślij dźwięk';

  @override
  String get sendFile => 'Wyślij plik';

  @override
  String get sendImage => 'Wyślij obraz';

  @override
  String get sendMessages => 'Wyślij wiadomości';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOriginal => 'Wyślij oryginał';

  @override
  String get sendSticker => 'Wyślij naklejkę';

  @override
  String get sendVideo => 'Wyślij film';

  @override
  String sentAFile(Object username) {
    return '$username wysłał/-a plik';
  }

  @override
  String sentAnAudio(Object username) {
    return '$username wysłał/-a plik audio';
  }

  @override
  String sentAPicture(Object username) {
    return '$username wysłał/-a obraz';
  }

  @override
  String sentASticker(Object username) {
    return '$username wysłał/-a naklejkę';
  }

  @override
  String sentAVideo(Object username) {
    return '$username wysłał/-a wideo';
  }

  @override
  String sentCallInformations(Object senderName) {
    return '$senderName sent call information';
  }

  @override
  String get separateChatTypes => 'Separate Direct Chats and Groups';

  @override
  String get setAsCanonicalAlias => 'Ustaw jako główny alias';

  @override
  String get setCustomEmotes => 'Ustaw niestandardowe emotki';

  @override
  String get setGroupDescription => 'Ustaw opis grupy';

  @override
  String get setInvitationLink => 'Ustaw link zaproszeniowy';

  @override
  String get setPermissionsLevel => 'Ustaw poziom uprawnień';

  @override
  String get setStatus => 'Ustaw status';

  @override
  String get settings => 'Ustawienia';

  @override
  String get share => 'Udostępnij';

  @override
  String sharedTheLocation(Object username) {
    return '$username udostępnił/-a lokalizacje';
  }

  @override
  String get shareLocation => 'Udostępnij lokalizację';

  @override
  String get showDirectChatsInSpaces => 'Show related Direct Chats in Spaces';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get signUp => 'Zarejestruj się';

  @override
  String get singlesignon => 'Single Sign on';

  @override
  String get skip => 'Pomiń';

  @override
  String get invite => 'Invite';

  @override
  String get sourceCode => 'Kod żródłowy';

  @override
  String get spaceIsPublic => 'Ustaw jako publiczną';

  @override
  String get spaceName => 'Nazwa przestrzeni';

  @override
  String startedACall(Object senderName) {
    return '$senderName rozpoczął rozmowę';
  }

  @override
  String get startFirstChat => 'Start your first chat';

  @override
  String get status => 'Status';

  @override
  String get statusExampleMessage => 'Jak się masz dziś?';

  @override
  String get submit => 'Submit';

  @override
  String get sunday => 'Niedziela';

  @override
  String get synchronizingPleaseWait => 'Synchronizacja… Proszę czekać.';

  @override
  String get systemTheme => 'System';

  @override
  String get theyDontMatch => 'Nie pasują';

  @override
  String get theyMatch => 'Pasują';

  @override
  String get thisRoomHasBeenArchived =>
      'Ten pokój został przeniesiony do archiwum.';

  @override
  String get thursday => 'Czwartek';

  @override
  String get title => 'FluffyChat';

  @override
  String get toggleFavorite => 'Przełącz ulubione';

  @override
  String get toggleMuted => 'Przełącz wyciszone';

  @override
  String get toggleUnread => 'Oznacz przeczytane/nieprzeczytane';

  @override
  String get tooManyRequestsWarning =>
      'Zbyt wiele zapytań. Proszę spróbuj ponownie później.';

  @override
  String get transferFromAnotherDevice => 'Przenieś z innego urządzenia';

  @override
  String get tryToSendAgain => 'Spróbuj wysłać ponownie';

  @override
  String get tuesday => 'Wtorek';

  @override
  String get unavailable => 'Niedostępne';

  @override
  String unbannedUser(Object username, Object targetName) {
    return '$username odbanował/-a $targetName';
  }

  @override
  String get unblockDevice => 'Unblock Device';

  @override
  String get unknownDevice => 'Nieznane urządzenie';

  @override
  String get unknownEncryptionAlgorithm => 'Nieznany algorytm szyfrowania';

  @override
  String unknownEvent(Object type, Object tipo) {
    return 'Nieznane zdarzenie \'$type\'';
  }

  @override
  String get unmuteChat => 'Wyłącz wyciszenie';

  @override
  String get unpin => 'Odepnij';

  @override
  String unreadChats(num unreadCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unreadCount,
      locale: localeName,
      other: '$unreadCount nieprzeczytanych czatów',
    );
    return '$_temp0';
  }

  @override
  String userAndOthersAreTyping(Object username, Object count) {
    return '$username oraz $count innych pisze';
  }

  @override
  String userAndUserAreTyping(Object username, Object username2) {
    return '$username oraz $username2 piszą';
  }

  @override
  String userIsTyping(Object username) {
    return '$username pisze';
  }

  @override
  String userLeftTheChat(Object username) {
    return '$username opuścił/-a czat';
  }

  @override
  String get username => 'Nick';

  @override
  String userSentUnknownEvent(Object username, Object type) {
    return '$username wysłał/-a wydarzenie $type';
  }

  @override
  String get unverified => 'Unverified';

  @override
  String get verified => 'Zweryfikowane';

  @override
  String get verify => 'zweryfikuj';

  @override
  String get verifyStart => 'Start Verification';

  @override
  String get verifySuccess => 'You successfully verified!';

  @override
  String get verifyTitle => 'Verifying other account';

  @override
  String get videoCall => 'Rozmowa wideo';

  @override
  String get visibilityOfTheChatHistory => 'Widoczność historii czatu';

  @override
  String get visibleForAllParticipants =>
      'Widoczny dla wszystkich użytkowników';

  @override
  String get visibleForEveryone => 'Widoczny dla każdego';

  @override
  String get voiceMessage => 'Wiadomość głosowa';

  @override
  String get waitingPartnerAcceptRequest =>
      'Waiting for partner to accept the request…';

  @override
  String get waitingPartnerEmoji => 'Waiting for partner to accept the emoji…';

  @override
  String get waitingPartnerNumbers =>
      'Waiting for partner to accept the numbers…';

  @override
  String get wallpaper => 'Tapeta';

  @override
  String get warning => 'Warning!';

  @override
  String get wednesday => 'Środa';

  @override
  String get weSentYouAnEmail => 'We sent you an email';

  @override
  String get whoCanPerformWhichAction => 'Who can perform which action';

  @override
  String get whoIsAllowedToJoinThisGroup => 'Kto może dołączyć do tej grupy';

  @override
  String get whyDoYouWantToReportThis => 'Why do you want to report this?';

  @override
  String get wipeChatBackup =>
      'Wipe your chat backup to create a new recovery key?';

  @override
  String get withTheseAddressesRecoveryDescription =>
      'Dzięki tym adresom możesz odzyskać swoje hasło.';

  @override
  String get writeAMessage => 'Napisz wiadomość…';

  @override
  String get yes => 'Tak';

  @override
  String get you => 'Ty';

  @override
  String get youAreInvitedToThisChat =>
      'Dostałeś/-aś zaproszenie do tego czatu';

  @override
  String get youAreNoLongerParticipatingInThisChat =>
      'Nie uczestniczysz już w tym czacie';

  @override
  String get youCannotInviteYourself => 'Nie możesz zaprosić siebie';

  @override
  String get youHaveBeenBannedFromThisChat =>
      'Zostałeś zbanowany na tym czacie';

  @override
  String get yourPublicKey => 'Twój klucz publiczny';

  @override
  String get messageInfo => 'Message info';

  @override
  String get time => 'Time';

  @override
  String get messageType => 'Message Type';

  @override
  String get sender => 'Sender';

  @override
  String get openGallery => 'Open gallery';

  @override
  String get removeFromSpace => 'Remove from space';

  @override
  String get addToSpaceDescription => 'Select a space to add this chat to it.';

  @override
  String get start => 'Start';

  @override
  String get pleaseEnterRecoveryKeyDescription =>
      'To unlock your old messages, please enter your recovery key that has been generated in a previous session. Your recovery key is NOT your password.';

  @override
  String get addToStory => 'Dodaj do relacji';

  @override
  String get publish => 'Opublikuj';

  @override
  String get whoCanSeeMyStories => 'Kto może widzieć moje relacje?';

  @override
  String get unsubscribeStories => 'Unsubscribe stories';

  @override
  String get thisUserHasNotPostedAnythingYet =>
      'This user has not posted anything in their story yet';

  @override
  String get yourStory => 'Twoja relacja';

  @override
  String get replyHasBeenSent => 'Reply has been sent';

  @override
  String videoWithSize(Object size) {
    return 'Video ($size)';
  }

  @override
  String storyFrom(Object date, Object body) {
    return 'Story from $date: \n$body';
  }

  @override
  String get whoCanSeeMyStoriesDesc =>
      'Please note that people can see and contact each other in your story.';

  @override
  String get whatIsGoingOn => 'Co u Ciebie słychać?';

  @override
  String get addDescription => 'Add description';

  @override
  String get storyPrivacyWarning =>
      'Please note that people can see and contact each other in your story. Your stories will be visible for 24 hours but there is no guarantee that they will be deleted from all devices and servers.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get openChat => 'Open Chat';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get reportUser => 'Report user';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get matrixWidgets => 'Matrix Widgets';

  @override
  String reactedWith(Object sender, Object reaction) {
    return '$sender reacted with $reaction';
  }

  @override
  String get pinChat => 'Pin';

  @override
  String get confirmEventUnpin =>
      'Are you sure to permanently unpin the message?';

  @override
  String get emojis => 'Emojis';

  @override
  String get placeCall => 'Place call';

  @override
  String get voiceCall => 'Voice call';

  @override
  String get unsupportedAndroidVersion => 'Unsupported Android version';

  @override
  String get unsupportedAndroidVersionLong =>
      'This feature requires a newer Android version. Please check for updates or Lineage OS support.';

  @override
  String get videoCallsBetaWarning =>
      'Please note that video calls are currently in beta. They might not work as expected or work at all on all platforms.';

  @override
  String get experimentalVideoCalls => 'Experimental video calls';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get indexedDbErrorTitle => 'Private mode issues';

  @override
  String get indexedDbErrorLong =>
      'The message storage is unfortunately not enabled in private mode by default.\nPlease visit\n - about:config\n - set dom.indexedDB.privateBrowsing.enabled to true\nOtherwise, it is not possible to run FluffyChat.';

  @override
  String switchToAccount(Object number) {
    return 'Switch to account $number';
  }

  @override
  String get nextAccount => 'Next account';

  @override
  String get previousAccount => 'Previous account';

  @override
  String get editWidgets => 'Edit widgets';

  @override
  String get addWidget => 'Add widget';

  @override
  String get widgetVideo => 'Video';

  @override
  String get widgetEtherpad => 'Text note';

  @override
  String get widgetJitsi => 'Jitsi Meet';

  @override
  String get widgetCustom => 'Custom';

  @override
  String get widgetName => 'Name';

  @override
  String get widgetUrlError => 'This is not a valid URL.';

  @override
  String get widgetNameError => 'Please provide a display name.';

  @override
  String get errorAddingWidget => 'Error adding the widget.';

  @override
  String get youRejectedTheInvitation => 'You rejected the invitation';

  @override
  String get youJoinedTheChat => 'You joined the chat';

  @override
  String get youAcceptedTheInvitation => '👍 You accepted the invitation';

  @override
  String youBannedUser(Object user) {
    return 'You banned $user';
  }

  @override
  String youHaveWithdrawnTheInvitationFor(Object user) {
    return 'You have withdrawn the invitation for $user';
  }

  @override
  String youInvitedBy(Object user) {
    return '📩 You have been invited by $user';
  }

  @override
  String youInvitedUser(Object user) {
    return '📩 You invited $user';
  }

  @override
  String youKicked(Object user) {
    return '👞 You kicked $user';
  }

  @override
  String youKickedAndBanned(Object user) {
    return '🙅 You kicked and banned $user';
  }

  @override
  String youUnbannedUser(Object user) {
    return 'You unbanned $user';
  }

  @override
  String get noEmailWarning =>
      'Please enter a valid email address. Otherwise you won\'t be able to reset your password. If you don\'t want to, tap again on the button to continue.';

  @override
  String get stories => 'Stories';

  @override
  String get users => 'Users';

  @override
  String get enableAutoBackups => 'Enable auto backups';

  @override
  String get unlockOldMessages => 'Unlock old messages';

  @override
  String get cannotUnlockBackupKey => 'Cannot unlock Key backup.';

  @override
  String get storeInSecureStorageDescription =>
      'Store the recovery key in the secure storage of this device.';

  @override
  String get saveKeyManuallyDescription =>
      'Save this key manually by triggering the system share dialog or clipboard.';

  @override
  String get storeInAndroidKeystore => 'Store in Android KeyStore';

  @override
  String get storeInAppleKeyChain => 'Store in Apple KeyChain';

  @override
  String get storeSecurlyOnThisDevice => 'Store securely on this device';

  @override
  String countFiles(Object count) {
    return '$count files';
  }

  @override
  String get user => 'User';

  @override
  String get custom => 'Custom';

  @override
  String get foregroundServiceRunning =>
      'This notification appears when the foreground service is running.';

  @override
  String get screenSharingTitle => 'screen sharing';

  @override
  String get screenSharingDetail => 'You are sharing your screen in FuffyChat';

  @override
  String get callingPermissions => 'Calling permissions';

  @override
  String get callingAccount => 'Calling account';

  @override
  String get callingAccountDetails =>
      'Allows FluffyChat to use the native android dialer app.';

  @override
  String get appearOnTop => 'Appear on top';

  @override
  String get appearOnTopDetails =>
      'Allows the app to appear on top (not needed if you already have Fluffychat setup as a calling account)';

  @override
  String get otherCallingPermissions =>
      'Microphone, camera and other FluffyChat permissions';

  @override
  String get whyIsThisMessageEncrypted => 'Why is this message unreadable?';

  @override
  String get noKeyForThisMessage =>
      'This can happen if the message was sent before you have signed in to your account at this device.\n\nIt is also possible that the sender has blocked your device or something went wrong with the internet connection.\n\nAre you able to read the message on another session? Then you can transfer the message from it! Go to Settings > Devices and make sure that your devices have verified each other. When you open the room the next time and both sessions are in the foreground, the keys will be transmitted automatically.\n\nDo you not want to loose the keys when logging out or switching devices? Make sure that you have enabled the chat backup in the settings.';

  @override
  String get newGroup => 'New chat';

  @override
  String get newSpace => 'New space';

  @override
  String get enterSpace => 'Enter space';

  @override
  String get enterRoom => 'Enter room';

  @override
  String get allSpaces => 'All spaces';

  @override
  String numChats(Object number) {
    return '$number chats';
  }

  @override
  String get hideUnimportantStateEvents => 'Hide unimportant state events';

  @override
  String get doNotShowAgain => 'Do not show again';

  @override
  String wasDirectChatDisplayName(Object oldDisplayName) {
    return 'Empty chat (was $oldDisplayName)';
  }

  @override
  String get newSpaceDescription =>
      'Spaces allows you to consolidate your chats and build private or public communities.';

  @override
  String get encryptThisChat => 'Encrypt this chat';

  @override
  String get endToEndEncryption => 'End to end encryption';

  @override
  String get disableEncryptionWarning =>
      'For security reasons you can not disable encryption in a chat, where it has been enabled before.';

  @override
  String get sorryThatsNotPossible => 'Sorry... that is not possible';

  @override
  String get deviceKeys => 'Device keys:';

  @override
  String get letsStart => 'Let\'s start';

  @override
  String get enterInviteLinkOrMatrixId => 'Enter invite link or Matrix ID...';

  @override
  String get reopenChat => 'Reopen chat';

  @override
  String get noBackupWarning =>
      'Warning! Without enabling chat backup, you will lose access to your encrypted messages. It is highly recommended to enable the chat backup first before logging out.';

  @override
  String get noOtherDevicesFound => 'No other devices found';

  @override
  String get fileIsTooBigForServer =>
      'The server reports that the file is too large to be sent.';

  @override
  String get onlineStatus => 'online';

  @override
  String onlineMinAgo(Object min) {
    return 'online ${min}m ago';
  }

  @override
  String onlineHourAgo(Object hour) {
    return 'online ${hour}h ago';
  }

  @override
  String onlineDayAgo(Object day) {
    return 'online ${day}d ago';
  }

  @override
  String get noMessageHereYet => 'No message here yet...';

  @override
  String get sendMessageGuide => 'Send a message or tap on the greeting below.';

  @override
  String get youCreatedGroupChat => 'You created a Group chat';

  @override
  String get chatCanHave => 'Chat can have:';

  @override
  String get upTo100000Members => 'Up to 100.000 members';

  @override
  String get persistentChatHistory => 'Persistent Chat history';

  @override
  String get addMember => 'Add members';

  @override
  String get profile => 'Profile';

  @override
  String get channels => 'Channels';

  @override
  String get chatMessage => 'New message';

  @override
  String welcomeToTwake(Object user) {
    return 'Welcome to Twake, $user';
  }

  @override
  String get startNewChatMessage =>
      'It\'s nice having a chat with your friends and collaborating with your teams.\nLet\'s start a chat, create a group chat, or join an existing one.';

  @override
  String get statusDot => '⬤';

  @override
  String get active => 'Activated';

  @override
  String get inactive => 'Not-activated';

  @override
  String get newGroupChat => 'New Group Chat';

  @override
  String get twakeUsers => 'Twake users';

  @override
  String get expand => 'Expand';

  @override
  String get shrink => 'Shrink';

  @override
  String noResultForKeyword(Object keyword) {
    return 'No results for \"$keyword\"';
  }

  @override
  String get searchResultNotFound1 =>
      '• Make sure there are no typos in your search.\n';

  @override
  String get searchResultNotFound2 =>
      '• You might not have the user in your address book.\n';

  @override
  String get searchResultNotFound3 =>
      '• Check the contact access permission, the user might be in your contact list.\n';

  @override
  String get searchResultNotFound4 => '• If the reason is not listed above, ';

  @override
  String get searchResultNotFound5 => 'seek helps.';

  @override
  String get more => 'More';

  @override
  String get whoWouldYouLikeToAdd => 'Who would you like to add?';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String maxImageSize(Object max) {
    return 'Maximum file size: ${max}MB';
  }

  @override
  String get owner => 'Owner';

  @override
  String participantsCount(Object count) {
    return 'Participants ($count)';
  }

  @override
  String get back => 'Back';

  @override
  String get wrongServerName => 'Wrong server name';

  @override
  String get serverNameWrongExplain =>
      'Server address was sent to you by company admin. Check the invitation email.';

  @override
  String get contacts => 'Contacts';

  @override
  String get searchForContacts => 'Search for contacts';

  @override
  String get soonThereHaveContacts => 'Soon there will be contacts';

  @override
  String get searchSuggestion =>
      'For now, search by typing a person’s name or public server address';

  @override
  String get loadingContacts => 'Loading contacts...';

  @override
  String get recentChat => 'RECENT CHAT';

  @override
  String get selectChat => 'Select chat';

  @override
  String get search => 'Szukaj';

  @override
  String get forwardTo => 'Forward to...';

  @override
  String get noConnection => 'No connection';

  @override
  String photoSelectedCounter(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0 selected';
  }

  @override
  String get addACaption => 'Add a caption...';

  @override
  String get noImagesFound => 'No Images found';

  @override
  String get captionForImagesIsNotSupportYet =>
      'Caption for images is not support yet.';

  @override
  String get tapToAllowAccessToYourGallery => 'Tap to allow gallery access';

  @override
  String get tapToAllowAccessToYourCamera =>
      'You can enable camera access in the Settings app to make video calls in';

  @override
  String get twake => 'Twake Chat';

  @override
  String get permissionAccess => 'Permission access';

  @override
  String get allow => 'Allow';

  @override
  String get explainStoragePermission =>
      'Twake need access to your storage to preview file';

  @override
  String get explainGoToStorageSetting =>
      'Twake need access to your storage to preview file, go to settings to allow this permission';

  @override
  String get gallery => 'Gallery';

  @override
  String get documents => 'Documents';

  @override
  String get location => 'Location';

  @override
  String get contact => 'Contact';

  @override
  String get file => 'File';

  @override
  String get recent => 'Recent';

  @override
  String get chatsAndContacts => 'Chats and Contacts';

  @override
  String get externalContactTitle => 'Invite new users';

  @override
  String get externalContactMessage =>
      'Some of the users you want to add are not in your contacts. Do you want to invite them?';

  @override
  String get clear => 'Clear';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get changeChatAvatar => 'Change the Chat avatar';

  @override
  String get roomAvatarMaxFileSize => 'The avatar size is too large';

  @override
  String roomAvatarMaxFileSizeLong(Object max) {
    return 'The avatar size must be less than $max';
  }

  @override
  String get continueProcess => 'Continue';

  @override
  String get youAreUploadingPhotosDoYouWantToCancelOrContinue =>
      'Image upload error! Do you still want to continue creating group chat?';

  @override
  String hasCreatedAGroupChat(Object groupName) {
    return 'created a group chat “$groupName”';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get acceptInvite => 'Yes please, join';

  @override
  String get askToInvite => ' wants you to join this chat. What do you say?';

  @override
  String get select => 'Select';

  @override
  String get copyMessageText => 'Copy';

  @override
  String get pinThisChat => 'Pin this chat';

  @override
  String get unpinThisChat => 'Unpin this chat';

  @override
  String get add => 'Add';

  @override
  String get addMembers => 'Add members';

  @override
  String get chatInfo => 'Chat info';

  @override
  String get mute => 'Mute';

  @override
  String membersInfo(Object count) {
    return 'Members ($count)';
  }

  @override
  String get members => 'Members';

  @override
  String get media => 'Media';

  @override
  String get files => 'Files';

  @override
  String get links => 'Links';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadImageSuccess => 'Image saved to Pictures';

  @override
  String get downloadImageError => 'Error saving image';

  @override
  String downloadFileInWeb(Object directory) {
    return 'File saved to $directory';
  }

  @override
  String get notInAChatYet => 'You\'re not in a chat yet';

  @override
  String get blankChatTitle => 'Choose a chat or hit #EditIcon# to make one.';

  @override
  String get errorPageTitle => 'Something\'s not right';

  @override
  String get errorPageDescription => 'That page doesn\'t exist.';

  @override
  String get errorPageButton => 'Back to chat';

  @override
  String get playVideo => 'Play';

  @override
  String get done => 'Done';

  @override
  String get markThisChatAsRead => 'Mark this chat as read';

  @override
  String get markThisChatAsUnRead => 'Mark this chat as unread';

  @override
  String get muteThisChat => 'Mute this chat';

  @override
  String get unmuteThisChat => 'Unmute this chat';

  @override
  String get read => 'Read';

  @override
  String get unread => 'Unread';

  @override
  String get unmute => 'Unmute';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get notificationAndSounds => 'Notification & Sounds';

  @override
  String get appLanguage => 'App Language';

  @override
  String get chatFolders => 'Chat Folders';

  @override
  String get displayName => 'Display Name';

  @override
  String get bio => 'Bio (optional)';

  @override
  String get matrixId => 'Matrix ID';

  @override
  String get email => 'Email';

  @override
  String get company => 'Company';

  @override
  String get basicInfo => 'BASIC INFO';

  @override
  String get editProfileDescriptions =>
      'Update your profile with a new name, picture and a short introduction.';

  @override
  String get workIdentitiesInfo => 'WORK IDENTITIES INFO';

  @override
  String get editWorkIdentitiesDescriptions =>
      'Edit your work identity settings such as Matrix ID, email or company name.';

  @override
  String get copiedMatrixIdToClipboard => 'Copied Matrix ID to clipboard.';

  @override
  String get changeProfileAvatar => 'Change profile avatar';

  @override
  String countPinChat(Object countPinChat) {
    return 'PINNED CHATS ($countPinChat)';
  }

  @override
  String countAllChat(Object countAllChat) {
    return 'ALL CHATS ($countAllChat)';
  }

  @override
  String get thisMessageHasBeenEncrypted => 'This message has been encrypted';

  @override
  String get roomCreationFailed => 'Room creation failed';

  @override
  String get errorGettingPdf => 'Error getting PDF';

  @override
  String get errorPreviewingFile => 'Error previewing file';

  @override
  String get paste => 'Paste';

  @override
  String get cut => 'Cut';

  @override
  String get pasteImageFailed => 'Paste image failed';

  @override
  String get copyImageFailed => 'Copy image failed';

  @override
  String get fileFormatNotSupported => 'File format not supported';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get encryptionMessage =>
      'This feature protects your messages from being read by others, but also prevents them from being backed up on our servers. You can\'t disable this later.';

  @override
  String get encryptionWarning =>
      'You might lose your messages if you access Twake app on the another device.';

  @override
  String get selectedUsers => 'Selected users';

  @override
  String get clearAllSelected => 'Clear all selected';

  @override
  String get newDirectMessage => 'New direct message';

  @override
  String get contactInfo => 'Contact info';

  @override
  String countPinnedMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pinned Message #$count',
      zero: 'Pinned Message',
    );
    return '$_temp0';
  }

  @override
  String pinnedMessages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pinned Messages',
      one: '1 Pinned Message',
    );
    return '$_temp0';
  }

  @override
  String get copyImageSuccess => 'Image copied to clipboard';

  @override
  String get youNeedToAcceptTheInvitation =>
      'You need to accept the invitation to start chatting';

  @override
  String get hasInvitedYouToAChat =>
      ' has invited you to a chat. Accept or reject and delete the conversation?';

  @override
  String get declineTheInvitation => 'Decline the invitation?';

  @override
  String get doYouReallyWantToDeclineThisInvitation =>
      'Do you really want to decline this invitation and remove the chat? You won\'t be able to undo this action.';

  @override
  String get declineAndRemove => 'Decline and remove';

  @override
  String get notNow => 'Not now';

  @override
  String get contactsWarningBannerTitle =>
      'To ensure you can connect with all your friends, please allow Twake to access your device’s contacts. We appreciate your understanding.';

  @override
  String contactsCount(Object count) {
    return 'Contacts ($count)';
  }

  @override
  String linagoraContactsCount(Object count) {
    return 'Linagora contacts ($count)';
  }

  @override
  String fetchingPhonebookContacts(Object progress) {
    return 'Fetching contacts from device...($progress% completed)';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get languageFrench => 'French';

  @override
  String get languageRussian => 'Russian';

  @override
  String get settingsLanguageDescription =>
      'Set the language you use on Twake Chat';

  @override
  String sendImages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count images',
      one: 'Send 1 image',
    );
    return '$_temp0';
  }

  @override
  String get enterCaption => 'Add a caption...';

  @override
  String get failToSend => 'Failed to send, please try again';

  @override
  String get showLess => 'Show Less';

  @override
  String get showMore => 'Show More';

  @override
  String get unreadMessages => 'Unread messages';

  @override
  String get groupInformation => 'Group information';

  @override
  String get linkInvite => 'Link invite';

  @override
  String get noDescription => 'No description';

  @override
  String get description => 'Description';

  @override
  String get groupName => 'Group name';

  @override
  String get descriptionHelper =>
      'You can provide an optional description for your group.';

  @override
  String get groupNameCannotBeEmpty => 'Group name cannot be empty';

  @override
  String get unpinAllMessages => 'Unpin all messages';

  @override
  String get pinnedMessagesTooltip => 'Pinned messages';

  @override
  String get jumpToMessage => 'Jump to message';

  @override
  String get failedToUnpin => 'Failed to unpin message';

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String get descriptionWelcomeTo =>
      'an open source messenger based on\nthe matrix protocol, which allows you to\nencrypt your data';

  @override
  String get startMessaging => 'Start messaging';

  @override
  String get signIn => 'Sign in';

  @override
  String get createTwakeId => 'Create Twake ID';

  @override
  String get useYourCompanyServer => 'Use your company server';

  @override
  String get descriptionTwakeId =>
      'An open source messenger encrypt\nyour data with matrix protocol';

  @override
  String countFilesSendPerDialog(Object count) {
    return 'The maximum files when sending is $count.';
  }

  @override
  String sendFiles(Object count) {
    return 'Send $count files';
  }

  @override
  String get addAnotherAccount => 'Add another account';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get failedToSendFiles => 'Failed to send files';

  @override
  String get noResults => 'No Results';

  @override
  String get isSingleAccountOnHomeserver =>
      'We do not yet support multiple accounts on a single homeserver';

  @override
  String messageSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Messages',
      one: '1 Message',
      zero: 'No Messages',
    );
    return '$_temp0 selected';
  }

  @override
  String draftChatHookPhrase(String user) {
    return 'Hi $user! I would like to chat with you.';
  }

  @override
  String get twakeChatUser => 'Twake Chat User';

  @override
  String get sharedMediaAndLinks => 'Shared media and links';

  @override
  String get errorSendingFiles =>
      'Some files aren’t sendable due to size, format restrictions, or unexpected errors. They’ll be omitted.';

  @override
  String get removeFileBeforeSend => 'Remove error files before send';

  @override
  String get unselect => 'Unselect';

  @override
  String get searchContacts => 'Search contacts';

  @override
  String get tapToAllowAccessToYourMicrophone =>
      'You can enable microphone access in the Settings app to make voice in';

  @override
  String get showInChat => 'Show in chat';

  @override
  String get phone => 'Phone';

  @override
  String get viewProfile => 'View profile';

  @override
  String get profileInfo => 'Profile informations';

  @override
  String get saveToDownloads => 'Save to Downloads';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get fileSavedToDownloads => 'File saved to Downloads';

  @override
  String get saveFileToDownloadsError => 'Failed to save file to Downloads';

  @override
  String explainPermissionToDownloadFiles(String appName) {
    return 'To continue, please allow $appName to access storage permission. This permission is essential for saving file to Downloads folder.';
  }

  @override
  String get explainPermissionToAccessContacts =>
      'Twake Chat DOES NOT collect your contacts. Twake Chat sends only contact hashes to the Twake Chat servers to understand who from your friends already joined Twake Chat, enabling connection with them. Your contacts ARE NOT synchronized with our server.';

  @override
  String get explainPermissionToAccessMedias =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Photos and Videos permission. You can also deny access to your media library at any time.';

  @override
  String get explainPermissionToAccessPhotos =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Photos permission. You can also deny access to your media library at any time.';

  @override
  String get explainPermissionToAccessVideos =>
      'Twake Chat does not synchronize data between your device and our servers. We only store media that you have sent to the chat room. All media files sent to chat are encrypted and stored securely. Go to Settings > Permissions and activate the Storage: Videos permission. You can also deny access to your media library at any time.';

  @override
  String get downloading => 'Downloading';

  @override
  String get settingUpYourTwake =>
      'Setting up your Twake\nIt could take a while';

  @override
  String get performingAutomaticalLogin =>
      'Performing automatical login  via SSO';

  @override
  String get backingUpYourMessage =>
      'Preparing server environment for backing up your messages';

  @override
  String get recoveringYourEncryptedChats => 'Recovering your encrypted chats';

  @override
  String get configureDataEncryption => 'Configure data encryption';

  @override
  String get configurationNotFound => 'The configuration data not found';

  @override
  String get fileSavedToGallery => 'File saved to Gallery';

  @override
  String get saveFileToGalleryError => 'Failed to save file to Gallery';

  @override
  String explainPermissionToGallery(String appName) {
    return 'To continue, please allow $appName to access photo permission. This permission is essential for saving file to gallery.';
  }

  @override
  String get tokenNotFound => 'The login token not found';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get leaveGroupSubtitle =>
      'This group will still remain after you left';

  @override
  String get leaveChatFailed => 'Failed to leave the chat';

  @override
  String get invalidLoginToken => 'Invalid login token';

  @override
  String get copiedPublicKeyToClipboard => 'Copied public key to clipboard.';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get removeUser => 'Remove User';

  @override
  String removeReason(Object user) {
    return 'Remove $user from the group';
  }

  @override
  String get switchAccounts => 'Switch accounts';

  @override
  String get selectAccount => 'Select account';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get byContinuingYourAgreeingToOur =>
      'By continuing, you\'re agreeing to our';

  @override
  String get youDontHaveAnyContactsYet => 'You dont have any contacts yet.';

  @override
  String get loading => 'Loading...';

  @override
  String get errorDialogTitle => 'Oops, something went wrong';

  @override
  String get shootingTips => 'Tap to take photo.';

  @override
  String get shootingWithRecordingTips =>
      'Tap to take photo. Long press to record video.';

  @override
  String get shootingOnlyRecordingTips => 'Long press to record video.';

  @override
  String get shootingTapRecordingTips => 'Tap to record video.';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get saving => 'Saving...';

  @override
  String get sActionManuallyFocusHint => 'Manually focus';

  @override
  String get sActionPreviewHint => 'Preview';

  @override
  String get sActionRecordHint => 'Record';

  @override
  String get sActionShootHint => 'Take picture';

  @override
  String get sActionShootingButtonTooltip => 'Shooting button';

  @override
  String get sActionStopRecordingHint => 'Stop recording';

  @override
  String sCameraLensDirectionLabel(Object value) {
    return 'Camera lens direction: $value';
  }

  @override
  String sCameraPreviewLabel(Object value) {
    return 'Camera preview: $value';
  }

  @override
  String sFlashModeLabel(Object mode) {
    return 'Flash mode: $mode';
  }

  @override
  String sSwitchCameraLensDirectionLabel(Object value) {
    return 'Switch to the $value camera';
  }

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get message => 'Message';

  @override
  String fileTooBig(int maxSize) {
    return 'The selected file is too large. Please choose a file smaller than $maxSize MB.';
  }

  @override
  String get enable_notifications => 'Enable notifications';

  @override
  String get disable_notifications => 'Disable notifications';

  @override
  String get logoutDialogWarning =>
      'You will lose access to encrypted messages. We recommend that you enable chat backups before logging out';

  @override
  String get copyNumber => 'Copy number';

  @override
  String get callViaCarrier => 'Call via Carrier';

  @override
  String get scanQrCodeToJoin =>
      'Installation of the mobile application will allow you to contact people from your phone\'s address book, your chats will be synchronised between devices';

  @override
  String get thisFieldCannotBeBlank => 'This field cannot be blank';

  @override
  String get phoneNumberCopiedToClipboard => 'Phone number copied to clipboard';

  @override
  String get deleteAccountMessage =>
      'Groups chats that you have created will remain unadministered unless you have given another user administrator rights. Users will still have a history of messages with you. Deleting the account won\'t help.';

  @override
  String get deleteLater => 'Delete later';

  @override
  String get areYouSureYouWantToDeleteAccount =>
      'Are you sure you want to delete account?';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get selectAnEmailOrPhoneYouWantSendTheInvitationTo =>
      'Select an email or phone you want send the invitation to';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get sendInvitation => 'Send invitation';

  @override
  String get verifyWithAnotherDevice => 'Verify with another device';

  @override
  String get contactLookupFailed => 'Contact lookup failed.';

  @override
  String get invitationHasBeenSuccessfullySent =>
      'Invitation has been successfully sent!';

  @override
  String get failedToSendInvitation => 'Failed to send invitation.';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get shareInvitationLink => 'Share invitation link';

  @override
  String get failedToGenerateInvitationLink =>
      'Failed to generate invitation link.';

  @override
  String get youAlreadySentAnInvitationToThisContact =>
      'You already sent an invitation to this contact';

  @override
  String get selectedEmailWillReceiveAnInvitationLinkAndInstructions =>
      'Selected email will receive an invitation link and instructions.';

  @override
  String get selectedNumberWillGetAnSMSWithAnInvitationLinkAndInstructions =>
      'Selected number will get an SMS with an invitation link and instructions.';

  @override
  String get reaction => 'Reaction';

  @override
  String get noChatPermissionMessage =>
      'You do not have permission to send messages in this chat.';

  @override
  String get administration => 'Administration';

  @override
  String get yourDataIsEncryptedForSecurity =>
      'Your data is encrypted for security';

  @override
  String get failedToDeleteMessage => 'Failed to delete message.';

  @override
  String get noDeletePermissionMessage =>
      'You don\'t have permission to delete this message.';

  @override
  String get edited => 'edited';

  @override
  String get editMessage => 'Edit message';

  @override
  String get assignRoles => 'Assign roles';

  @override
  String get permissions => 'Permissions';

  @override
  String adminsOfTheGroup(Object number) {
    return 'ADMINS OF THE GROUP ($number)';
  }

  @override
  String get addAdminsOrModerators => 'Add Admins/moderators';

  @override
  String get member => 'Member';

  @override
  String get guest => 'Guest';

  @override
  String get exceptions => 'Exceptions';

  @override
  String get readOnly => 'Read only';

  @override
  String readOnlyCount(Object number) {
    return 'READ ONLY ($number)';
  }

  @override
  String get removedUsers => 'Removed Users';

  @override
  String bannedUsersCount(Object number) {
    return 'BANNED USERS ($number)';
  }

  @override
  String get downgradeToReadOnly => 'Downgrade to read only';

  @override
  String memberOfTheGroup(Object number) {
    return 'MEMBERS OF THE GROUP ($number)';
  }

  @override
  String get selectRole => 'Select role';

  @override
  String get canReadMessages => 'Can read messages';

  @override
  String get canWriteMessagesSendReacts => 'Can write messages, send reacts...';

  @override
  String get canRemoveUsersDeleteMessages =>
      'Can remove users, delete messages...';

  @override
  String get canAccessAllFeaturesAndSettings =>
      'Can access all features and settings';

  @override
  String get invitePeopleToTheRoom => 'Invite people to the room';

  @override
  String get sendReactions => 'Send reactions';

  @override
  String get deleteMessagesSentByMe => 'Delete messages sent by me';

  @override
  String get notifyEveryoneUsingRoom => 'Notify everyone using @room';

  @override
  String get joinCall => 'Join Call';

  @override
  String get removeMembers => 'Remove a members';

  @override
  String get deleteMessagesSentByOthers => 'Delete messages sent by others';

  @override
  String get pinMessageForEveryone => 'Pin a message (for everyone)';

  @override
  String get startCall => 'Start Call';

  @override
  String get changeGroupName => 'Change group name';

  @override
  String get changeGroupDescription => 'Change group description';

  @override
  String get changeGroupAvatar => 'Change group avatar';

  @override
  String get changeGroupHistoryVisibility => 'Change group history visibility';

  @override
  String get searchGroupMembers => 'Search group members';

  @override
  String get permissionErrorChangeRole =>
      'You don’t have the rights to change roles. Please reach out to your admin for help';

  @override
  String get demoteAdminsModerators => 'Demote Admins/Moderators';

  @override
  String get deleteMessageConfirmationTitle =>
      'Are you sure you want to delete this message?';

  @override
  String get permissionErrorBanUser =>
      'You don’t have the rights to ban users. Please reach out to your admin for help';

  @override
  String get removeMember => 'Remove member';

  @override
  String get removeMemberSelectionError =>
      'You cannot delete a member with a role equal to or greater than yours.';

  @override
  String get downgrade => 'Downgrade';

  @override
  String get deletedMessage => 'Deleted message';

  @override
  String get unban => 'Unban';

  @override
  String get permissionErrorUnbanUser =>
      'You don’t have the rights to unban users. Please reach out to your admin for help';

  @override
  String get transferOwnership => 'Transfer ownership';

  @override
  String confirmTransferOwnership(Object name) {
    return 'Are you sure you want to transfer ownership of this group to $name?';
  }

  @override
  String get transferOwnershipDescription =>
      'This user will gain full control over the group and you will no longer have total management rights. This action is irreversible.';

  @override
  String get confirmTransfer => 'Confirm Transfer';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get blockUser => 'Block User';

  @override
  String get permissionErrorUnblockUser =>
      'You don’t have the rights to unblock user.';

  @override
  String get permissionErrorBlockUser =>
      'You don’t have the rights to block user.';

  @override
  String userIsNotAValidMxid(Object mxid) {
    return '$mxid is not a valid Matrix ID';
  }

  @override
  String userNotFoundInIgnoreList(Object mxid) {
    return '$mxid is not found in your ignore list';
  }

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String unblockUsername(Object name) {
    return 'Unblock $name';
  }

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockDescriptionDialog =>
      'This person will be able to message you and see when you\'re online. They won\'t be notified that you unblocked them.';

  @override
  String get report => 'Report';

  @override
  String get reportDesc => 'What’s the issue with this message?';

  @override
  String get sendReport => 'Send Report';

  @override
  String get addComment => 'Add comment';

  @override
  String get spam => 'Spam';

  @override
  String get violence => 'Violence';

  @override
  String get childAbuse => 'Child abuse';

  @override
  String get pornography => 'Pornography';

  @override
  String get copyrightInfringement => 'Copyright infringement';

  @override
  String get terrorism => 'Terrorism';

  @override
  String get other => 'Other';

  @override
  String get enableRightAndLeftMessageAlignment =>
      'Enable right/left message alignment';

  @override
  String get holdToRecordAudio => 'Hold to record audio.';

  @override
  String get explainPermissionToAccessMicrophone =>
      'To send voice messages, allow Twake Chat to access the microphone.';

  @override
  String get allowMicrophoneAccess => 'Allow microphone access';

  @override
  String get later => 'Later';

  @override
  String get couldNotPlayAudioFile => 'Could not play audio file';

  @override
  String get slideToCancel => 'Slide to cancel';

  @override
  String get recordingInProgress => 'Recording in progress';

  @override
  String get pleaseFinishOrStopTheRecording =>
      'Please finish or stop the recording before performing other actions.';

  @override
  String get audioMessageFailedToSend => 'Audio message failed to send.';
}
